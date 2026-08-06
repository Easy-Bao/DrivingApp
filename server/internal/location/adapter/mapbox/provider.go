package mapbox

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
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
	searchURL                      = "https://api.mapbox.com/search/searchbox/v1"
	geocodingURL                   = "https://api.mapbox.com/search/geocode/v6"
	directionsURL                  = "https://api.mapbox.com/directions/v5/mapbox"
	nearbyPageSize                 = 10
	maxNearbyPage                  = 100
	maxSearchQueryBytes            = 256
	maxProviderResponseBytes int64 = 4 << 20
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
		MapboxID       string          `json:"mapbox_id"`
		Name           string          `json:"name"`
		PreferredName  string          `json:"name_preferred"`
		FeatureType    string          `json:"feature_type"`
		Address        string          `json:"full_address"`
		ShortAddress   string          `json:"address"`
		PlaceFormatted string          `json:"place_formatted"`
		Category       json.RawMessage `json:"poi_category"`
		Coordinates    struct {
			Latitude  *float64 `json:"latitude"`
			Longitude *float64 `json:"longitude"`
			Accuracy  string   `json:"accuracy"`
		} `json:"coordinates"`
		Context map[string]featureContext `json:"context"`
	} `json:"properties"`
	Geometry struct {
		Coordinates []float64 `json:"coordinates"`
	} `json:"geometry"`
	FeatureType string `json:"feature_type"`
}

type featureContext struct {
	Name string `json:"name"`
}

type categoryResult struct {
	places []domain.Place
	err    error
}

func (provider *Provider) Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error) {
	if len([]byte(query)) > maxSearchQueryBytes || !origin.Valid() {
		return nil, fmt.Errorf("invalid location search")
	}
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
	if page < 1 || page > maxNearbyPage || !origin.Valid() {
		return nil, fmt.Errorf("invalid nearby page or coordinates")
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
	longitude, latitude, ok := featureCoordinates(feature)
	if !ok {
		return domain.Place{}, false
	}
	name := feature.Properties.Name
	if name == "" {
		name = feature.Properties.PreferredName
	}
	if name == "" {
		name = feature.Properties.ShortAddress
	}
	if name == "" {
		name = feature.Properties.PlaceFormatted
	}
	address := feature.Properties.Address
	if address == "" {
		address = feature.Properties.ShortAddress
	}
	if address == "" {
		address = feature.Properties.PlaceFormatted
	}
	return domain.Place{
		ID:         featureID(feature),
		Name:       name,
		Address:    address,
		Category:   categoryName(feature.Properties.Category),
		Longitude:  longitude,
		Latitude:   latitude,
		DistanceKm: haversine(origin.Latitude, origin.Longitude, latitude, longitude),
		Context:    featureContextNames(feature),
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
	}
	var response featureResponse
	if err := provider.getJSON(ctx, searchURL+"/reverse?"+queryParams.Encode(), &response); err != nil {
		return nil, err
	}
	selected, match, ok := mostSpecificReverseFeature(response.Features, coordinates)
	if !ok {
		fallbackQuery := url.Values{
			"longitude":    {coordinate(coordinates.Longitude)},
			"latitude":     {coordinate(coordinates.Latitude)},
			"access_token": {provider.token},
			"limit":        {"1"},
		}
		if err := provider.getJSON(ctx, geocodingURL+"/reverse?"+fallbackQuery.Encode(), &response); err != nil {
			return nil, err
		}
		selected, match, ok = mostSpecificReverseFeature(response.Features, coordinates)
	}
	if !ok {
		return nil, fmt.Errorf("mapbox returned no place")
	}
	place, _ := placeFromFeature(selected, coordinates)
	place.MatchType = match.matchType
	place.DistanceMeters = match.distanceMeters
	place.Confidence = match.confidence
	return &place, nil
}

type reverseMatch struct {
	matchType      string
	distanceMeters float64
	confidence     float64
}

type reverseCandidateRank struct {
	stage       int
	prominence  int
	distanceMtr float64
}

func mostSpecificReverseFeature(features []feature, origin domain.Coordinates) (feature, reverseMatch, bool) {
	var selected feature
	var selectedMatch reverseMatch
	selectedRank := reverseCandidateRank{stage: math.MaxInt, prominence: -1, distanceMtr: math.MaxFloat64}
	found := false
	for _, candidate := range features {
		longitude, latitude, ok := featureCoordinates(candidate)
		if !ok {
			continue
		}
		distanceMeters := haversine(origin.Latitude, origin.Longitude, latitude, longitude) * 1000
		rank := reverseCandidateRankFor(candidate, distanceMeters)
		if !found || rank.stage < selectedRank.stage ||
			(rank.stage == selectedRank.stage && rank.prominence > selectedRank.prominence) ||
			(rank.stage == selectedRank.stage && rank.prominence == selectedRank.prominence && rank.distanceMtr < selectedRank.distanceMtr) {
			selected = candidate
			selectedMatch = reverseMatchFor(candidate, distanceMeters)
			selectedRank = rank
			found = true
		}
	}
	return selected, selectedMatch, found
}

func reverseCandidateRankFor(candidate feature, distanceMeters float64) reverseCandidateRank {
	featureType := featureType(candidate)
	stage := 4
	switch {
	case distanceMeters <= 15 && (featureType == "address" || featureType == "poi"):
		stage = 0
	case distanceMeters <= 100 && (featureType == "address" || featureType == "poi"):
		stage = 1
	case featureType == "street":
		stage = 2
	case featureType == "locality" || featureType == "place" || featureType == "district" || featureType == "region":
		stage = 3
	}
	return reverseCandidateRank{
		stage:       stage,
		prominence:  reverseFeatureProminence(candidate),
		distanceMtr: distanceMeters,
	}
}

func reverseMatchFor(candidate feature, distanceMeters float64) reverseMatch {
	featureType := featureType(candidate)
	accuracy := strings.ToLower(candidate.Properties.Coordinates.Accuracy)
	matchType := "area"
	switch {
	case distanceMeters <= 15 && (accuracy == "rooftop" || accuracy == "parcel" || accuracy == "point"):
		matchType = "direct"
	case distanceMeters <= 100 && featureType == "poi":
		matchType = "nearby_poi"
	case distanceMeters <= 100 && featureType == "address":
		matchType = "interpolated"
	case featureType == "street":
		matchType = "road"
	}
	return reverseMatch{
		matchType:      matchType,
		distanceMeters: distanceMeters,
		confidence:     reverseConfidence(matchType, distanceMeters),
	}
}

func reverseFeatureProminence(candidate feature) int {
	featureType := featureType(candidate)
	if featureType != "poi" {
		switch featureType {
		case "address":
			return 5
		case "street":
			return 4
		case "locality", "place", "district", "region":
			return 2
		default:
			return 1
		}
	}
	prominence := 6
	for _, rawCategory := range categoryValues(candidate.Properties.Category) {
		category := strings.ToLower(rawCategory)
		if strings.Contains(category, "transit") || strings.Contains(category, "airport") || strings.Contains(category, "hospital") {
			prominence = 10
			break
		}
		if strings.Contains(category, "university") || strings.Contains(category, "school") || strings.Contains(category, "government") {
			prominence = 9
		}
	}
	return prominence
}

func categoryValues(raw json.RawMessage) []string {
	if len(raw) == 0 {
		return nil
	}
	var categories []string
	if json.Unmarshal(raw, &categories) == nil {
		return categories
	}
	var category string
	if json.Unmarshal(raw, &category) == nil && category != "" {
		return []string{category}
	}
	return nil
}

func reverseConfidence(matchType string, distanceMeters float64) float64 {
	base := map[string]float64{
		"direct":       0.98,
		"interpolated": 0.82,
		"nearby_poi":   0.76,
		"road":         0.64,
		"area":         0.45,
	}[matchType]
	confidence := base - math.Min(distanceMeters/1000, 1)*0.15
	return math.Max(0.1, math.Round(confidence*100)/100)
}

func featureType(candidate feature) string {
	result := strings.ToLower(candidate.Properties.FeatureType)
	if result == "" {
		result = strings.ToLower(candidate.FeatureType)
	}
	return result
}

func featureID(candidate feature) string {
	if candidate.ID != "" {
		return candidate.ID
	}
	return candidate.Properties.MapboxID
}

func featureCoordinates(candidate feature) (float64, float64, bool) {
	if len(candidate.Geometry.Coordinates) >= 2 {
		return candidate.Geometry.Coordinates[0], candidate.Geometry.Coordinates[1], true
	}
	if candidate.Properties.Coordinates.Longitude == nil || candidate.Properties.Coordinates.Latitude == nil {
		return 0, 0, false
	}
	return *candidate.Properties.Coordinates.Longitude, *candidate.Properties.Coordinates.Latitude, true
}

func featureContextNames(candidate feature) map[string]string {
	if len(candidate.Properties.Context) == 0 {
		return nil
	}
	contextNames := make(map[string]string, len(candidate.Properties.Context))
	for key, value := range candidate.Properties.Context {
		if strings.TrimSpace(value.Name) != "" {
			contextNames[key] = value.Name
		}
	}
	if len(contextNames) == 0 {
		return nil
	}
	return contextNames
}

type directionsResponse struct {
	Routes []mapboxRoute `json:"routes"`
}

type mapboxRoute struct {
	Distance float64 `json:"distance"`
	Duration float64 `json:"duration"`
	Geometry struct {
		Coordinates [][]float64 `json:"coordinates"`
	} `json:"geometry"`
}

func (provider *Provider) Route(ctx context.Context, origin, destination domain.Coordinates, options domain.RouteOptions) (*domain.Route, error) {
	if !origin.Valid() || !destination.Valid() {
		return nil, fmt.Errorf("invalid route coordinates")
	}
	normalizedOptions, err := options.Normalize()
	if err != nil {
		return nil, err
	}
	coordinates := strings.Join([]string{
		coordinate(origin.Longitude) + "," + coordinate(origin.Latitude),
		coordinate(destination.Longitude) + "," + coordinate(destination.Latitude),
	}, ";")
	queryParams := url.Values{
		"access_token": {provider.token},
		"alternatives": {"true"},
		"overview":     {"full"},
		"geometries":   {"geojson"},
	}
	if len(normalizedOptions.ExcludePoints) > 0 {
		excludedPoints := make([]string, 0, len(normalizedOptions.ExcludePoints))
		for _, point := range normalizedOptions.ExcludePoints {
			excludedPoints = append(excludedPoints, fmt.Sprintf("point(%s %s)", coordinate(point.Longitude), coordinate(point.Latitude)))
		}
		queryParams.Set("exclude", strings.Join(excludedPoints, ","))
	}
	var response directionsResponse
	endpoint := directionsURL + "/" + string(normalizedOptions.Profile) + "/" + coordinates + "?" + queryParams.Encode()
	if err := provider.getJSON(ctx, endpoint, &response); err != nil {
		return nil, err
	}
	if len(response.Routes) == 0 {
		return nil, fmt.Errorf("mapbox returned no route")
	}
	selected := selectRoute(response.Routes, normalizedOptions.Preference)
	return &domain.Route{
		Origin:      origin,
		Destination: destination,
		Preference:  string(normalizedOptions.Preference),
		Profile:     string(normalizedOptions.Profile),
		DistanceKm:  selected.Distance / 1000,
		DurationMin: selected.Duration / 60,
		Polyline:    selected.Geometry.Coordinates,
	}, nil
}

func selectRoute(routes []mapboxRoute, preference domain.RoutePreference) mapboxRoute {
	selected := routes[0]
	for _, candidate := range routes[1:] {
		if preference == domain.RoutePreferenceShortest {
			if candidate.Distance < selected.Distance {
				selected = candidate
			}
			continue
		}
		if candidate.Duration < selected.Duration {
			selected = candidate
		}
	}
	return selected
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
	return json.NewDecoder(io.LimitReader(response.Body, maxProviderResponseBytes)).Decode(target)
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
