package mapbox

import (
	"context"
	"io"
	"math"
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
	provider := NewMapboxProvider("test-token")
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
	provider := NewMapboxProvider("test-token")
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

func TestPlaceFromFeatureRejectsOutOfRangeCoordinates(t *testing.T) {
	candidate := feature{}
	candidate.Geometry.Coordinates = []float64{181, 91}

	if _, ok := placeFromFeature(candidate, domain.Coordinates{}); ok {
		t.Fatal("expected out-of-range provider coordinates to be rejected")
	}
}

func TestProviderRejectsTrailingResponseData(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			return responseWithBody(request, `{"features":[]} {}`), nil
		}),
	}

	_, err := provider.Search(context.Background(), "Pagadian", domain.Coordinates{Latitude: 7.8, Longitude: 123.4})
	if err == nil {
		t.Fatal("expected trailing provider data to be rejected")
	}
}

func TestHaversineRemainsFiniteForAntipodalCoordinates(t *testing.T) {
	distance := haversine(0, 0, 0, 180)
	if math.IsNaN(distance) || math.IsInf(distance, 0) || distance <= 0 {
		t.Fatalf("antipodal distance = %v, want a finite positive value", distance)
	}
}

func TestReverseGeocodeChoosesMostSpecificFeature(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			body := `{"features":[
				{"id":"place","properties":{"name":"Pagadian City","feature_type":"place"},"geometry":{"coordinates":[123.4361,7.8282]}},
				{"id":"address","properties":{"name":"Antonio Salazar Street","feature_type":"address","full_address":"Antonio Salazar Street, Pagadian City","coordinates":{"accuracy":"rooftop"}},"geometry":{"coordinates":[123.4361,7.8282]}}
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
	if place.MatchType != "direct" || place.DistanceMeters != 0 {
		t.Fatalf("expected a direct match at the tapped coordinate, got %#v", place)
	}
}

func TestReverseGeocodeFallsBackToGeocodingWhenSearchBoxIsEmpty(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	var paths []string
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			paths = append(paths, request.URL.Path)
			if request.URL.Path == "/search/searchbox/v1/reverse" {
				return responseWithBody(request, `{"features":[]}`), nil
			}
			return responseWithBody(request, `{"features":[{"id":"street.1","properties":{"name":"Main Street","feature_type":"street","place_formatted":"Tuburan, Zamboanga del Sur","context":{"place":{"name":"Tuburan"}}},"geometry":{"coordinates":[123.43635,7.8282]}}]}`), nil
		}),
	}

	place, err := provider.ReverseGeocode(context.Background(), domain.Coordinates{
		Latitude:  7.8282,
		Longitude: 123.4361,
	})
	if err != nil {
		t.Fatalf("reverse geocode fallback failed: %v", err)
	}
	if place.Name != "Main Street" || place.MatchType != "road" {
		t.Fatalf("expected the fallback street match, got %#v", place)
	}
	if place.DistanceMeters <= 0 || place.Confidence <= 0 {
		t.Fatalf("expected fallback match metadata, got %#v", place)
	}
	if place.Context["place"] != "Tuburan" {
		t.Fatalf("expected fallback context, got %#v", place.Context)
	}
	if len(paths) != 2 || paths[0] != "/search/searchbox/v1/reverse" || paths[1] != "/search/geocode/v6/reverse" {
		t.Fatalf("expected Search Box then Geocoding fallback, got %#v", paths)
	}
}

func TestReverseGeocodeUsesProminenceWithinRadialStage(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			body := `{"features":[
				{"id":"small-shop","properties":{"name":"Small Shop","feature_type":"poi","poi_category":["shop"]},"geometry":{"coordinates":[123.43628,7.8282]}},
				{"id":"transit-hub","properties":{"name":"Transit Hub","feature_type":"poi","poi_category":["transit"]},"geometry":{"coordinates":[123.43645,7.8282]}}
			]}`
			return responseWithBody(request, body), nil
		}),
	}

	place, err := provider.ReverseGeocode(context.Background(), domain.Coordinates{
		Latitude:  7.8282,
		Longitude: 123.4361,
	})
	if err != nil {
		t.Fatalf("reverse geocode failed: %v", err)
	}
	if place.Name != "Transit Hub" {
		t.Fatalf("expected the prominent nearby POI, got %#v", place)
	}
	if place.MatchType != "nearby_poi" || place.DistanceMeters <= 0 {
		t.Fatalf("expected radial POI metadata, got %#v", place)
	}
}

func TestRouteSelectsByRequestedPreference(t *testing.T) {
	tests := []struct {
		name        string
		preference  domain.RoutePreference
		expectedKm  float64
		expectedMin float64
	}{
		{
			name:        "fastest",
			preference:  domain.RoutePreferenceFastest,
			expectedKm:  3,
			expectedMin: 5,
		},
		{
			name:        "shortest",
			preference:  domain.RoutePreferenceShortest,
			expectedKm:  2,
			expectedMin: 8.333333333333334,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			provider := NewMapboxProvider("test-token")
			provider.client = &http.Client{
				Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
					if request.URL.Path != "/directions/v5/mapbox/driving/123.400000,7.800000;123.500000,7.900000" {
						t.Fatalf("unexpected directions path: %s", request.URL.Path)
					}
					if request.URL.Query().Get("alternatives") != "true" {
						t.Fatal("expected alternatives to be requested")
					}
					body := `{"routes":[
						{"distance":3000,"duration":300,"geometry":{"coordinates":[[123.4,7.8],[123.5,7.9]]}},
						{"distance":2000,"duration":500,"geometry":{"coordinates":[[123.4,7.8],[123.45,7.85],[123.5,7.9]]}}
					]}`
					return &http.Response{
						StatusCode: http.StatusOK,
						Body:       io.NopCloser(strings.NewReader(body)),
						Header:     make(http.Header),
						Request:    request,
					}, nil
				}),
			}

			route, err := provider.Route(context.Background(), domain.Coordinates{
				Latitude:  7.8,
				Longitude: 123.4,
			}, domain.Coordinates{
				Latitude:  7.9,
				Longitude: 123.5,
			}, domain.RouteOptions{Preference: test.preference})
			if err != nil {
				t.Fatalf("route failed: %v", err)
			}
			if route.DistanceKm != test.expectedKm || route.DurationMin != test.expectedMin {
				t.Fatalf("unexpected route metrics: %#v", route)
			}
			if route.Preference != string(test.preference) || route.Profile != string(domain.RouteProfileDriving) {
				t.Fatalf("unexpected route options: %#v", route)
			}
		})
	}
}

func TestRouteShortestPreferenceKeepsPrimaryRouteForMarginalSavings(t *testing.T) {
	routes := []mapboxRoute{
		{
			Distance: 2500,
			Duration: 480,
		},
		{
			Distance: 2400,
			Duration: 540,
		},
	}

	selected := selectRoute(routes, domain.RoutePreferenceShortest)
	if selected.Distance != 2500 || selected.Duration != 480 {
		t.Fatalf("expected the primary route for a marginal distance saving, got %#v", selected)
	}
}

func TestRouteSupportsTrafficProfileAndExcludedRoadPoints(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			if request.URL.Path != "/directions/v5/mapbox/driving-traffic/123.400000,7.800000;123.500000,7.900000" {
				t.Fatalf("unexpected directions path: %s", request.URL.Path)
			}
			if got := request.URL.Query().Get("exclude"); got != "point(123.400000 7.800000),point(123.450000 7.850000)" {
				t.Fatalf("unexpected excluded points: %s", got)
			}
			body := `{"routes":[{"distance":3000,"duration":300,"geometry":{"coordinates":[[123.4,7.8],[123.5,7.9]]}}]}`
			return &http.Response{
				StatusCode: http.StatusOK,
				Body:       io.NopCloser(strings.NewReader(body)),
				Header:     make(http.Header),
				Request:    request,
			}, nil
		}),
	}

	route, err := provider.Route(context.Background(), domain.Coordinates{
		Latitude:  7.8,
		Longitude: 123.4,
	}, domain.Coordinates{
		Latitude:  7.9,
		Longitude: 123.5,
	}, domain.RouteOptions{
		Profile: domain.RouteProfileDrivingTraffic,
		ExcludePoints: []domain.Coordinates{
			{Latitude: 7.8, Longitude: 123.4},
			{Latitude: 7.85, Longitude: 123.45},
		},
	})
	if err != nil {
		t.Fatalf("route failed: %v", err)
	}
	if route.Profile != string(domain.RouteProfileDrivingTraffic) {
		t.Fatalf("expected traffic profile, got %#v", route)
	}
}

func TestMatrixUsesOneBoundedProviderRequestAndConvertsUnits(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	requestCount := 0
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			requestCount++
			if request.URL.Path != "/directions-matrix/v1/mapbox/driving/123.400000,7.800000;123.500000,7.900000;123.600000,8.000000" {
				t.Fatalf("unexpected matrix path: %s", request.URL.Path)
			}
			if request.URL.Query().Get("sources") != "0" || request.URL.Query().Get("destinations") != "1;2" {
				t.Fatalf("unexpected matrix indexes: %s", request.URL.RawQuery)
			}
			if request.URL.Query().Get("annotations") != "distance,duration" {
				t.Fatalf("unexpected matrix annotations: %s", request.URL.RawQuery)
			}
			return responseWithBody(request, `{"code":"Ok","distances":[[1250,3500]],"durations":[[180,420]]}`), nil
		}),
	}

	matrix, err := provider.Matrix(
		context.Background(),
		domain.Coordinates{Latitude: 7.8, Longitude: 123.4},
		[]domain.Coordinates{
			{Latitude: 7.9, Longitude: 123.5},
			{Latitude: 8, Longitude: 123.6},
		},
	)
	if err != nil {
		t.Fatalf("matrix failed: %v", err)
	}
	if requestCount != 1 {
		t.Fatalf("provider requests = %d, want 1", requestCount)
	}
	if len(matrix.DistancesKm) != 2 || matrix.DistancesKm[0] != 1.25 || matrix.DistancesKm[1] != 3.5 {
		t.Fatalf("unexpected distances: %#v", matrix.DistancesKm)
	}
	if matrix.DurationsMin[0] != 3 || matrix.DurationsMin[1] != 7 {
		t.Fatalf("unexpected durations: %#v", matrix.DurationsMin)
	}
}

func TestMatrixUsesDirectionsForOneDestination(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			if !strings.HasPrefix(request.URL.Path, "/directions/v5/mapbox/driving/") {
				t.Fatalf("one destination used the wrong endpoint: %s", request.URL.Path)
			}
			return responseWithBody(request, `{"routes":[{"distance":1250,"duration":180,"geometry":{"coordinates":[]}}]}`), nil
		}),
	}

	matrix, err := provider.Matrix(
		context.Background(),
		domain.Coordinates{Latitude: 7.8, Longitude: 123.4},
		[]domain.Coordinates{{Latitude: 7.9, Longitude: 123.5}},
	)
	if err != nil {
		t.Fatalf("single-destination matrix failed: %v", err)
	}
	if len(matrix.DistancesKm) != 1 || matrix.DistancesKm[0] != 1.25 || matrix.DurationsMin[0] != 3 {
		t.Fatalf("unexpected single-destination matrix: %#v", matrix)
	}
}

func TestMatrixRejectsUnreachableDestinations(t *testing.T) {
	provider := NewMapboxProvider("test-token")
	provider.client = &http.Client{
		Transport: roundTripFunc(func(request *http.Request) (*http.Response, error) {
			return responseWithBody(request, `{"code":"Ok","distances":[[1250,null]],"durations":[[180,null]]}`), nil
		}),
	}

	_, err := provider.Matrix(
		context.Background(),
		domain.Coordinates{Latitude: 7.8, Longitude: 123.4},
		[]domain.Coordinates{
			{Latitude: 7.9, Longitude: 123.5},
			{Latitude: 8, Longitude: 123.6},
		},
	)
	if err == nil {
		t.Fatal("expected an unreachable destination to reject the matrix")
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (roundTrip roundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return roundTrip(request)
}

func responseWithBody(request *http.Request, body string) *http.Response {
	return &http.Response{
		StatusCode: http.StatusOK,
		Body:       io.NopCloser(strings.NewReader(body)),
		Header:     make(http.Header),
		Request:    request,
	}
}
