package mapbox

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

const (
	searchURL     = "https://api.mapbox.com/search/searchbox/v1"
	directionsURL = "https://api.mapbox.com/directions/v5/mapbox/driving"
)

type Provider struct {
	token  string
	client *http.Client
}

func NewProvider(token string) *Provider {
	return &Provider{
		token:  token,
		client: &http.Client{Timeout: 5 * time.Second},
	}
}

type featureResponse struct {
	Features []struct {
		ID         string `json:"id"`
		Properties struct {
			Name     string `json:"name"`
			Address  string `json:"full_address"`
			Category string `json:"poi_category"`
		} `json:"properties"`
		Geometry struct {
			Coordinates []float64 `json:"coordinates"`
		} `json:"geometry"`
	} `json:"features"`
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
		if len(feature.Geometry.Coordinates) < 2 {
			continue
		}
		places = append(places, domain.Place{
			ID:         feature.ID,
			Name:       feature.Properties.Name,
			Address:    feature.Properties.Address,
			Category:   feature.Properties.Category,
			Longitude:  feature.Geometry.Coordinates[0],
			Latitude:   feature.Geometry.Coordinates[1],
			DistanceKm: haversine(origin.Latitude, origin.Longitude, feature.Geometry.Coordinates[1], feature.Geometry.Coordinates[0]),
		})
	}
	return places, nil
}

func (provider *Provider) ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error) {
	queryParams := url.Values{
		"longitude":    {coordinate(coordinates.Longitude)},
		"latitude":     {coordinate(coordinates.Latitude)},
		"access_token": {provider.token},
		"limit":        {"1"},
		"types":        {"poi,address,street,place"},
	}
	var response featureResponse
	if err := provider.getJSON(ctx, searchURL+"/reverse?"+queryParams.Encode(), &response); err != nil {
		return nil, err
	}
	if len(response.Features) == 0 || len(response.Features[0].Geometry.Coordinates) < 2 {
		return nil, fmt.Errorf("mapbox returned no place")
	}
	feature := response.Features[0]
	return &domain.Place{
		ID:        feature.ID,
		Name:      feature.Properties.Name,
		Address:   feature.Properties.Address,
		Category:  feature.Properties.Category,
		Longitude: feature.Geometry.Coordinates[0],
		Latitude:  feature.Geometry.Coordinates[1],
	}, nil
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
