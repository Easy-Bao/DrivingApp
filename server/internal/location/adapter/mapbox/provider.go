package mapbox

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/resilience"
)

const (
	searchURL      = "https://api.mapbox.com/search/searchbox/v1"
	directionsURL  = "https://api.mapbox.com/directions/v5/mapbox/driving"
	nearbyPageSize = 10
)

var defaultNearbyCategories = []string{
	"food_and_drink",
	"hotel",
	"hospital",
	"school",
	"gas_station",
	"bank",
	"shopping_mall",
	"park",
}

type Provider struct {
	token            string
	client           *http.Client
	breaker          *resilience.CircuitBreaker
	nearbyCategories []string
}

func NewProvider(token string) *Provider {
	return &Provider{
		token:   token,
		client:  &http.Client{Timeout: 5 * time.Second},
		breaker: resilience.NewCircuitBreaker(5, 30*time.Second),
	}
}

type featureResponse struct {
	Features []feature `json:"features"`
}

type feature struct {
	ID         string `json:"id"`
	Properties struct {
		Name           string          `json:"name"`
		PreferredName  string          `json:"name_preferred"`
		FeatureType    string          `json:"feature_type"`
		Address        string          `json:"full_address"`
		ShortAddress   string          `json:"address"`
		PlaceFormatted string          `json:"place_formatted"`
		Category       json.RawMessage `json:"poi_category"`
	} `json:"properties"`
	Geometry struct {
		Coordinates []float64 `json:"coordinates"`
	} `json:"geometry"`
	FeatureType string `json:"feature_type"`
}

type categoryResult struct {
	places []domain.Place
	err    error
}

func (provider *Provider) Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error) {
	queryParams := url.Values{
		"q":            {query},
		"access_token": {provider.token},
		"limit":        {"10"},
		"types":        {"poi,address,place"},
		"proximity":    {coordinate(origin.Longitude) + "," + coordinate(origin.Latitude)},
	}
	var response featureResponse
	if err := provider.getJSON(ctx, searchURL+"/forward?"+queryParams.Encode(), &response); err != nil {
		return nil, err
	}
	places := make([]domain.Place, 0, len(response.Features))
	for _, feature := range response.Features {
		if place, ok := placeFromFeature(feature, origin); ok {
			places = append(places, place)
		}
	}
	return places, nil
}

func (provider *Provider) Nearby(ctx context.Context, origin domain.Coordinates, page int) ([]domain.Place, error) {
	if page < 1 {
		page = 1
	}
	categories := provider.nearbyCategories
	if len(categories) == 0 {
		categories = defaultNearbyCategories
	}

	results := make(chan categoryResult, len(categories))
	var waitGroup sync.WaitGroup
	for _, category := range categories {
		category := category
		waitGroup.Add(1)
		go func() {
			defer waitGroup.Done()
			results <- provider.nearbyCategory(ctx, origin, category)
		}()
	}
	waitGroup.Wait()
	close(results)

	places := make([]domain.Place, 0)
	var firstErr error
	for result := range results {
		if result.err != nil {
			if firstErr == nil {
				firstErr = result.err
			}
			continue
		}
		places = append(places, result.places...)
	}
	if len(places) == 0 && firstErr != nil {
		return nil, firstErr
	}

	places = uniqueNearbyPlaces(places)
	sort.SliceStable(places, func(i, j int) bool {
		if places[i].DistanceKm == places[j].DistanceKm {
			return places[i].Name < places[j].Name
		}
		return places[i].DistanceKm < places[j].DistanceKm
	})

	start := (page - 1) * nearbyPageSize
	if start >= len(places) {
		return []domain.Place{}, nil
	}
	end := start + nearbyPageSize
	if end > len(places) {
		end = len(places)
	}
	return places[start:end], nil
}

func (provider *Provider) nearbyCategory(ctx context.Context, origin domain.Coordinates, category string) categoryResult {
	queryParams := url.Values{
		"access_token": {provider.token},
		"limit":        {"25"},
		"proximity":    {coordinate(origin.Longitude) + "," + coordinate(origin.Latitude)},
	}
	var response featureResponse
	if err := provider.getJSON(ctx, searchURL+"/category/"+url.PathEscape(category)+"?"+queryParams.Encode(), &response); err != nil {
		return categoryResult{err: err}
	}
	places := make([]domain.Place, 0, len(response.Features))
	for _, feature := range response.Features {
		if place, ok := placeFromFeature(feature, origin); ok {
			places = append(places, place)
		}
	}
	return categoryResult{places: places}
}

func placeFromFeature(feature feature, origin domain.Coordinates) (domain.Place, bool) {
	if len(feature.Geometry.Coordinates) < 2 {
		return domain.Place{}, false
	}
	name := feature.Properties.Name
	if name == "" {
		name = feature.Properties.PreferredName
	}
	address := feature.Properties.Address
	if address == "" {
		address = feature.Properties.ShortAddress
	}
	if address == "" {
		address = feature.Properties.PlaceFormatted
	}
	return domain.Place{
		ID:         feature.ID,
		Name:       name,
		Address:    address,
		Category:   categoryName(feature.Properties.Category),
		Longitude:  feature.Geometry.Coordinates[0],
		Latitude:   feature.Geometry.Coordinates[1],
		DistanceKm: haversine(origin.Latitude, origin.Longitude, feature.Geometry.Coordinates[1], feature.Geometry.Coordinates[0]),
	}, true
}

func categoryName(raw json.RawMessage) string {
	if len(raw) == 0 {
		return ""
	}
	var category string
	if json.Unmarshal(raw, &category) == nil {
		return category
	}
	var categories []string
	if json.Unmarshal(raw, &categories) == nil && len(categories) > 0 {
		return categories[0]
	}
	return ""
}

func uniqueNearbyPlaces(places []domain.Place) []domain.Place {
	seen := make(map[string]struct{}, len(places))
	unique := make([]domain.Place, 0, len(places))
	for _, place := range places {
		key := place.ID
		if key == "" {
			key = coordinate(place.Latitude) + "," + coordinate(place.Longitude)
		}
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		unique = append(unique, place)
	}
	return unique
}

func (provider *Provider) ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error) {
	queryParams := url.Values{
		"longitude":    {coordinate(coordinates.Longitude)},
		"latitude":     {coordinate(coordinates.Latitude)},
		"access_token": {provider.token},
		"limit":        {"10"},
		"types":        {"poi,address,street,neighborhood,locality,place"},
	}
	var response featureResponse
	if err := provider.getJSON(ctx, searchURL+"/reverse?"+queryParams.Encode(), &response); err != nil {
		return nil, err
	}
	feature, ok := mostSpecificReverseFeature(response.Features, coordinates)
	if !ok {
		return nil, fmt.Errorf("mapbox returned no place")
	}
	place, _ := placeFromFeature(feature, coordinates)
	return &place, nil
}

func mostSpecificReverseFeature(features []feature, origin domain.Coordinates) (feature, bool) {
	var selected feature
	selectedScore := -1
	selectedDistance := math.MaxFloat64
	found := false
	for _, candidate := range features {
		if len(candidate.Geometry.Coordinates) < 2 {
			continue
		}
		score := reverseFeatureScore(candidate)
		distance := haversine(
			origin.Latitude,
			origin.Longitude,
			candidate.Geometry.Coordinates[1],
			candidate.Geometry.Coordinates[0],
		)
		if !found || score > selectedScore ||
			(score == selectedScore && distance < selectedDistance) {
			selected = candidate
			selectedScore = score
			selectedDistance = distance
			found = true
		}
	}
	return selected, found
}

func reverseFeatureScore(candidate feature) int {
	featureType := strings.ToLower(candidate.Properties.FeatureType)
	if featureType == "" {
		featureType = strings.ToLower(candidate.FeatureType)
	}
	switch featureType {
	case "poi":
		return 6
	case "address":
		return 5
	case "street":
		return 4
	case "neighborhood":
		return 3
	case "locality":
		return 2
	case "place":
		return 1
	default:
		return 0
	}
}

type directionsResponse struct {
	Routes []struct {
		Distance float64 `json:"distance"`
		Duration float64 `json:"duration"`
		Geometry struct {
			Coordinates [][]float64 `json:"coordinates"`
		} `json:"geometry"`
	} `json:"routes"`
}

func (provider *Provider) Route(ctx context.Context, origin, destination domain.Coordinates) (*domain.Route, error) {
	coordinates := strings.Join([]string{
		coordinate(origin.Longitude) + "," + coordinate(origin.Latitude),
		coordinate(destination.Longitude) + "," + coordinate(destination.Latitude),
	}, ";")
	queryParams := url.Values{
		"access_token": {provider.token},
		"overview":     {"full"},
		"geometries":   {"geojson"},
	}
	var response directionsResponse
	if err := provider.getJSON(ctx, directionsURL+"/"+coordinates+"?"+queryParams.Encode(), &response); err != nil {
		return nil, err
	}
	if len(response.Routes) == 0 {
		return nil, fmt.Errorf("mapbox returned no route")
	}
	selected := response.Routes[0]
	return &domain.Route{
		Origin:      origin,
		Destination: destination,
		DistanceKm:  selected.Distance / 1000,
		DurationMin: selected.Duration / 60,
		Polyline:    selected.Geometry.Coordinates,
	}, nil
}

func (provider *Provider) getJSON(ctx context.Context, endpoint string, target any) error {
	if provider.breaker == nil {
		provider.breaker = resilience.NewCircuitBreaker(5, 30*time.Second)
	}
	return provider.breaker.Do(ctx, func(ctx context.Context) error {
		return provider.fetchJSON(ctx, endpoint, target)
	})
}

func (provider *Provider) fetchJSON(ctx context.Context, endpoint string, target any) error {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return err
	}
	response, err := provider.client.Do(request)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		return fmt.Errorf("location provider returned status %d", response.StatusCode)
	}
	return json.NewDecoder(response.Body).Decode(target)
}

func coordinate(value float64) string {
	return strconv.FormatFloat(value, 'f', 6, 64)
}

func haversine(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadiusKm = 6371.0
	const radians = math.Pi / 180
	dLat := (lat2 - lat1) * radians
	dLng := (lng2 - lng1) * radians
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*radians)*math.Cos(lat2*radians)*math.Sin(dLng/2)*math.Sin(dLng/2)
	return earthRadiusKm * 2 * math.Asin(math.Sqrt(a))
}
