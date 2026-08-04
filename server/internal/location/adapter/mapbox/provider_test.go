package mapbox

import (
	"context"
	"io"
	"net/http"
	"strings"
	"sync"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

func TestNearbyUsesCategorySearchAndParsesMapboxCategories(t *testing.T) {
	var (
		mu    sync.Mutex
		paths []string
	)
	provider := NewProvider("test-token")
	provider.nearbyCategories = []string{"hospital", "school"}
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			mu.Lock()
			paths = append(paths, request.URL.Path)
			mu.Unlock()

			id := "hospital-1"
			name := "Pagadian Hospital"
			category := "hospital"
			if strings.HasSuffix(request.URL.Path, "/school") {
				id = "school-1"
				name = "Pagadian School"
				category = "school"
			}
			body := `{"features":[{"id":"` + id + `","properties":{"name":"` + name + `","full_address":"Pagadian City","poi_category":["` + category + `"]},"geometry":{"coordinates":[123.4361,7.8282]}}]}`
			return &http.Response{
				StatusCode: http.StatusOK,
				Body:       io.NopCloser(strings.NewReader(body)),
				Header:     make(http.Header),
				Request:    request,
			}, nil
		}),
	}

	places, err := provider.Nearby(context.Background(), domain.Coordinates{
		Latitude:  7.8282,
		Longitude: 123.4361,
	}, 1)
	if err != nil {
		t.Fatalf("nearby failed: %v", err)
	}
	if len(places) != 2 {
		t.Fatalf("expected two nearby places, got %d", len(places))
	}
	if places[0].Category == "" || places[1].Category == "" {
		t.Fatalf("expected categories to be decoded: %#v", places)
	}
	if places[0].DistanceKm != 0 || places[1].DistanceKm != 0 {
		t.Fatalf("expected distances from the origin, got %#v", places)
	}

	mu.Lock()
	defer mu.Unlock()
	for _, path := range paths {
		if !strings.Contains(path, "/category/") || strings.Contains(path, "/forward") {
			t.Fatalf("nearby used an invalid Mapbox endpoint: %s", path)
		}
	}
}

func TestNearbyPaginatesMergedResults(t *testing.T) {
	provider := NewProvider("test-token")
	provider.nearbyCategories = []string{"hospital"}
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			body := `{"features":[
				{"id":"one","properties":{"name":"One"},"geometry":{"coordinates":[123.4361,7.8282]}},
				{"id":"two","properties":{"name":"Two"},"geometry":{"coordinates":[123.4362,7.8282]}}
			]}`
			return &http.Response{
				StatusCode: http.StatusOK,
				Body:       io.NopCloser(strings.NewReader(body)),
				Header:     make(http.Header),
				Request:    request,
			}, nil
		}),
	}

	origin := domain.Coordinates{Latitude: 7.8282, Longitude: 123.4361}
	pageOne, err := provider.Nearby(context.Background(), origin, 1)
	if err != nil || len(pageOne) != 2 {
		t.Fatalf("page one = %#v, %v", pageOne, err)
	}
	pageTwo, err := provider.Nearby(context.Background(), origin, 2)
	if err != nil || len(pageTwo) != 0 {
		t.Fatalf("page two = %#v, %v", pageTwo, err)
	}
}

func TestReverseGeocodeChoosesMostSpecificFeature(t *testing.T) {
	provider := NewProvider("test-token")
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			body := `{"features":[
				{"id":"place","properties":{"name":"Pagadian City","feature_type":"place"},"geometry":{"coordinates":[123.4361,7.8282]}},
				{"id":"address","properties":{"name":"Antonio Salazar Street","feature_type":"address","full_address":"Antonio Salazar Street, Pagadian City"},"geometry":{"coordinates":[123.4361,7.8282]}}
			]}`
			return &http.Response{
				StatusCode: http.StatusOK,
				Body:       io.NopCloser(strings.NewReader(body)),
				Header:     make(http.Header),
				Request:    request,
			}, nil
		}),
	}

	place, err := provider.ReverseGeocode(context.Background(), domain.Coordinates{
		Latitude:  7.8282,
		Longitude: 123.4361,
	})
	if err != nil {
		t.Fatalf("reverse geocode failed: %v", err)
	}
	if place.Name != "Antonio Salazar Street" {
		t.Fatalf("expected the address feature, got %#v", place)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (roundTrip roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return roundTrip(request)
}
