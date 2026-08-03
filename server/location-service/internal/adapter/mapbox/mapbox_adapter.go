package mapbox

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"location-service/internal/domain"
	"location-service/internal/usecase"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	searchBoxBaseURL  = "https://api.mapbox.com/search/searchbox/v1"
	directionsBaseURL = "https://api.mapbox.com/directions/v5/mapbox/driving"
	matrixBaseURL     = "https://api.mapbox.com/directions-matrix/v1/mapbox/driving"
	nearbyRadiusKm    = 5.0
	upstreamTimeout   = 5 * time.Second
)

type mapboxAdapter struct {
	accessToken string
	httpClient  *http.Client
}

func NewMapboxAdapter(accessToken string) domain.LocationRepository {
	return &mapboxAdapter{
		accessToken: accessToken,
		httpClient: &http.Client{
			Timeout: upstreamTimeout,
		},
	}
}

type featureCollection struct {
	Features []mapboxFeature `json:"features"`
}

type mapboxFeature struct {
	ID         string                 `json:"id"`
	Properties map[string]interface{} `json:"properties"`
	Geometry   struct {
		Coordinates []float64 `json:"coordinates"`
	} `json:"geometry"`
}

func (adapter *mapboxAdapter) SearchPlaces(
	ctx context.Context,
	query string,
	latitude float64,
	longitude float64,
) ([]domain.Place, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return []domain.Place{}, nil
	}

	parameters := url.Values{
		"q":            {query},
		"access_token": {adapter.accessToken},
		"limit":        {"10"},
		"types":        {"poi,address,place"},
		"proximity":    {formatCoordinate(longitude) + "," + formatCoordinate(latitude)},
	}
	return adapter.fetchPlaces(ctx, searchBoxBaseURL+"/forward?"+parameters.Encode(), latitude, longitude)
}

func (adapter *mapboxAdapter) ReverseGeocode(
	ctx context.Context,
	latitude float64,
	longitude float64,
) (*domain.Place, error) {
	parameters := url.Values{
		"longitude":    {formatCoordinate(longitude)},
		"latitude":     {formatCoordinate(latitude)},
		"access_token": {adapter.accessToken},
		"limit":        {"10"},
		"types":        {"poi,address,street,place"},
	}
	places, err := adapter.fetchPlaces(ctx, searchBoxBaseURL+"/reverse?"+parameters.Encode(), latitude, longitude)
	if err != nil {
		return nil, err
	}
	if len(places) == 0 {
		return nil, fmt.Errorf("mapbox returned no place for coordinates")
	}
	return selectBestReversePlace(places), nil
}

func selectBestReversePlace(places []domain.Place) *domain.Place {
	sort.SliceStable(places, func(i, j int) bool {
		priorityI := reversePlacePriority(places[i].Category)
		priorityJ := reversePlacePriority(places[j].Category)
		if priorityI != priorityJ {
			return priorityI < priorityJ
		}
		return places[i].DistanceKm < places[j].DistanceKm
	})
	return &places[0]
}

func reversePlacePriority(category string) int {
	category = strings.ToLower(category)
	switch {
	case strings.Contains(category, "poi"):
		return 0
	case strings.Contains(category, "address"):
		return 1
	case strings.Contains(category, "street"):
		return 2
	default:
		return 3
	}
}

func (adapter *mapboxAdapter) GetNearbyPois(
	ctx context.Context,
	latitude float64,
	longitude float64,
	page int,
) ([]domain.Place, error) {
	_ = page
	categories := []string{"restaurant", "hotel", "hospital", "school", "pharmacy", "bank", "gas_station"}
	requestCtx, cancel := context.WithTimeout(ctx, upstreamTimeout)
	defer cancel()
	type sampleResult struct {
		places []domain.Place
		err    error
	}
	results := make(chan sampleResult, len(categories))
	var waitGroup sync.WaitGroup

	for _, category := range categories {
		waitGroup.Add(1)
		go func(category string) {
			defer waitGroup.Done()
			parameters := url.Values{
				"proximity":    {formatCoordinate(longitude) + "," + formatCoordinate(latitude)},
				"access_token": {adapter.accessToken},
				"limit":        {"10"},
			}
			places, err := adapter.fetchPlaces(
				requestCtx,
				searchBoxBaseURL+"/category/"+url.PathEscape(category)+"?"+parameters.Encode(),
				latitude,
				longitude,
			)
			results <- sampleResult{places: places, err: err}
		}(category)
	}
	waitGroup.Wait()
	close(results)

	uniquePlaces := make(map[string]domain.Place)
	var lastError error
	for result := range results {
		if result.err != nil {
			lastError = result.err
			continue
		}
		for _, place := range result.places {
			if place.DistanceKm <= nearbyRadiusKm {
				uniquePlaces[nearbyPlaceKey(place)] = place
			}
		}
	}
	if len(uniquePlaces) == 0 && lastError != nil {
		return nil, lastError
	}

	result := make([]domain.Place, 0, len(uniquePlaces))
	for _, place := range uniquePlaces {
		result = append(result, place)
	}
	return result, nil
}

func nearbyPlaceKey(place domain.Place) string {
	if place.ID != "" {
		return place.ID
	}
	return fmt.Sprintf(
		"%s:%.5f:%.5f",
		strings.ToLower(strings.TrimSpace(place.Name)),
		place.Latitude,
		place.Longitude,
	)
}

func (adapter *mapboxAdapter) GetRoute(
	ctx context.Context,
	originLatitude float64,
	originLongitude float64,
	destinationLatitude float64,
	destinationLongitude float64,
) (*domain.Route, error) {
	coordinates := strings.Join([]string{
		formatCoordinate(originLongitude) + "," + formatCoordinate(originLatitude),
		formatCoordinate(destinationLongitude) + "," + formatCoordinate(destinationLatitude),
	}, ";")
	parameters := url.Values{
		"access_token":      {adapter.accessToken},
		"alternatives":      {"true"},
		"continue_straight": {"false"},
		"overview":          {"full"},
		"geometries":        {"geojson"},
	}

	var response struct {
		Routes []mapboxRoute `json:"routes"`
	}
	if err := adapter.getJSON(ctx, directionsBaseURL+"/"+coordinates+"?"+parameters.Encode(), &response); err != nil {
		return nil, err
	}
	selectedRoute, ok := selectBestRoute(response.Routes)
	if !ok {
		return nil, fmt.Errorf("mapbox returned no route geometry")
	}

	return &domain.Route{
		OriginLat:      originLatitude,
		OriginLng:      originLongitude,
		DestLat:        destinationLatitude,
		DestLng:        destinationLongitude,
		DistanceKm:     selectedRoute.Distance / 1000,
		DurationMin:    selectedRoute.Duration / 60,
		PolylinePoints: selectedRoute.Geometry.Coordinates,
	}, nil
}

func (adapter *mapboxAdapter) GetTravelMatrix(
	ctx context.Context,
	origin domain.Point,
	destinations []domain.Point,
) (*domain.MatrixResult, error) {
	coordinates := make([]string, 0, len(destinations)+1)
	coordinates = append(coordinates, formatCoordinate(origin.Longitude)+","+formatCoordinate(origin.Latitude))
	for _, destination := range destinations {
		coordinates = append(coordinates, formatCoordinate(destination.Longitude)+","+formatCoordinate(destination.Latitude))
	}
	parameters := url.Values{
		"access_token": {adapter.accessToken},
		"sources":      {"0"},
		"annotations":  {"distance,duration"},
	}
	parameters.Set("destinations", matrixDestinationIndexes(len(destinations)))

	var response struct {
		Distances [][]float64 `json:"distances"`
		Durations [][]float64 `json:"durations"`
	}
	if err := adapter.getJSON(ctx, matrixBaseURL+"/"+strings.Join(coordinates, ";")+"?"+parameters.Encode(), &response); err != nil {
		return nil, err
	}
	return &domain.MatrixResult{
		DistancesKm:  metersToKilometers(firstMatrixRow(response.Distances)),
		DurationsMin: secondsToMinutes(firstMatrixRow(response.Durations)),
	}, nil
}

func firstMatrixRow(matrix [][]float64) []float64 {
	if len(matrix) == 0 {
		return nil
	}
	return matrix[0]
}

func matrixDestinationIndexes(count int) string {
	indexes := make([]string, count)
	for index := range indexes {
		indexes[index] = strconv.Itoa(index + 1)
	}
	return strings.Join(indexes, ";")
}

func metersToKilometers(values []float64) []float64 {
	converted := make([]float64, len(values))
	for index, value := range values {
		converted[index] = value / 1000
	}
	return converted
}

func secondsToMinutes(values []float64) []float64 {
	converted := make([]float64, len(values))
	for index, value := range values {
		converted[index] = value / 60
	}
	return converted
}

type mapboxRoute struct {
	Distance float64 `json:"distance"`
	Duration float64 `json:"duration"`
	Geometry struct {
		Coordinates [][]float64 `json:"coordinates"`
	} `json:"geometry"`
}

func selectBestRoute(routes []mapboxRoute) (mapboxRoute, bool) {
	validRoutes := make([]mapboxRoute, 0, len(routes))
	for _, route := range routes {
		if len(route.Geometry.Coordinates) >= 2 {
			validRoutes = append(validRoutes, route)
		}
	}
	if len(validRoutes) == 0 {
		return mapboxRoute{}, false
	}

	sort.SliceStable(validRoutes, func(i, j int) bool {
		if validRoutes[i].Distance == validRoutes[j].Distance {
			return validRoutes[i].Duration < validRoutes[j].Duration
		}
		return validRoutes[i].Distance < validRoutes[j].Distance
	})
	return validRoutes[0], true
}

func (adapter *mapboxAdapter) fetchPlaces(
	ctx context.Context,
	endpoint string,
	latitude float64,
	longitude float64,
) ([]domain.Place, error) {
	var response featureCollection
	if err := adapter.getJSON(ctx, endpoint, &response); err != nil {
		return nil, err
	}

	places := make([]domain.Place, 0, len(response.Features))
	for _, feature := range response.Features {
		if len(feature.Geometry.Coordinates) < 2 {
			continue
		}
		placeLongitude := feature.Geometry.Coordinates[0]
		placeLatitude := feature.Geometry.Coordinates[1]
		placeName := propertyString(feature.Properties, "name")
		if placeName == "" {
			placeName = propertyString(feature.Properties, "name_preferred")
		}
		address := propertyString(feature.Properties, "full_address")
		if address == "" {
			address = propertyString(feature.Properties, "place_formatted")
		}
		if address == "" {
			address = propertyString(feature.Properties, "address")
		}
		places = append(places, domain.Place{
			ID:         firstNonEmpty(feature.ID, propertyString(feature.Properties, "mapbox_id")),
			Name:       placeName,
			Address:    address,
			Category:   propertyString(feature.Properties, "feature_type"),
			Latitude:   placeLatitude,
			Longitude:  placeLongitude,
			DistanceKm: usecase.CalculateHaversine(latitude, longitude, placeLatitude, placeLongitude),
		})
	}
	return places, nil
}

func (adapter *mapboxAdapter) getJSON(ctx context.Context, endpoint string, target interface{}) error {
	if adapter.accessToken == "" {
		return fmt.Errorf("MAPBOX_ACCESS_TOKEN is not configured")
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return fmt.Errorf("create mapbox request: %w", err)
	}
	response, err := adapter.httpClient.Do(request)
	if err != nil {
		return fmt.Errorf("request mapbox: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		body, _ := io.ReadAll(io.LimitReader(response.Body, 1024))
		return fmt.Errorf("mapbox returned %s: %s", response.Status, strings.TrimSpace(string(body)))
	}
	if err := json.NewDecoder(response.Body).Decode(target); err != nil {
		return fmt.Errorf("decode mapbox response: %w", err)
	}
	return nil
}

func propertyString(properties map[string]interface{}, key string) string {
	value, ok := properties[key].(string)
	if !ok {
		return ""
	}
	return value
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}

func formatCoordinate(coordinate float64) string {
	return strconv.FormatFloat(coordinate, 'f', 6, 64)
}
