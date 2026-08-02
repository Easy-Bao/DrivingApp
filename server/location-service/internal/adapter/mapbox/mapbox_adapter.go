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
	"strconv"
	"strings"
	"time"
)

const (
	searchBoxBaseURL  = "https://api.mapbox.com/search/searchbox/v1"
	directionsBaseURL = "https://api.mapbox.com/directions/v5/mapbox/driving"
)

type mapboxAdapter struct {
	accessToken string
	httpClient  *http.Client
}

func NewMapboxAdapter(accessToken string) domain.LocationRepository {
	return &mapboxAdapter{
		accessToken: accessToken,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
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
		"limit":        {"1"},
	}
	places, err := adapter.fetchPlaces(ctx, searchBoxBaseURL+"/reverse?"+parameters.Encode(), latitude, longitude)
	if err != nil {
		return nil, err
	}
	if len(places) == 0 {
		return nil, fmt.Errorf("mapbox returned no place for coordinates")
	}
	return &places[0], nil
}

func (adapter *mapboxAdapter) GetNearbyPois(
	ctx context.Context,
	latitude float64,
	longitude float64,
	page int,
) ([]domain.Place, error) {
	if page < 1 {
		page = 1
	}
	parameters := url.Values{
		"longitude":    {formatCoordinate(longitude)},
		"latitude":     {formatCoordinate(latitude)},
		"access_token": {adapter.accessToken},
		"limit":        {"10"},
		"types":        {"poi"},
	}
	return adapter.fetchPlaces(ctx, searchBoxBaseURL+"/reverse?"+parameters.Encode(), latitude, longitude)
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
		"access_token": {adapter.accessToken},
		"overview":     {"full"},
		"geometries":   {"geojson"},
	}

	var response struct {
		Routes []struct {
			Distance float64 `json:"distance"`
			Duration float64 `json:"duration"`
			Geometry struct {
				Coordinates [][]float64 `json:"coordinates"`
			} `json:"geometry"`
		} `json:"routes"`
	}
	if err := adapter.getJSON(ctx, directionsBaseURL+"/"+coordinates+"?"+parameters.Encode(), &response); err != nil {
		return nil, err
	}
	if len(response.Routes) == 0 || len(response.Routes[0].Geometry.Coordinates) < 2 {
		return nil, fmt.Errorf("mapbox returned no route geometry")
	}

	selectedRoute := response.Routes[0]
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
