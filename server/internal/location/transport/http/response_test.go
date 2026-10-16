package http

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	trackingdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
)

func TestNewPlaceResponsesKeepsPublicFields(t *testing.T) {
	places := []domain.Place{{
		ID:             "place.1",
		Name:           "Pagadian Terminal",
		Address:        "Pagadian City",
		Category:       "transport",
		Latitude:       6.7,
		Longitude:      122.1,
		DistanceKm:     1.25,
		MatchType:      "exact",
		DistanceMeters: 1250,
		Confidence:     0.97,
		Context:        map[string]string{"city": "Pagadian"},
	}}
	encoded, err := json.Marshal(NewPlaceResponses(places))
	if err != nil {
		t.Fatalf("marshal place responses: %v", err)
	}
	const want = `[{"id":"place.1","name":"Pagadian Terminal","address":"Pagadian City","category":"transport","lat":6.7,"lng":122.1,"distance_km":1.25,"match_type":"exact","distance_meters":1250,"confidence":0.97,"context":{"city":"Pagadian"}}]`
	if string(encoded) != want {
		t.Fatalf("place responses = %s, want %s", encoded, want)
	}
}

func TestNewRouteAndMatrixResponsesKeepPublicFields(t *testing.T) {
	route := NewRouteResponse(&domain.Route{
		Origin:      domain.Coordinates{Latitude: 6.7, Longitude: 122.1},
		Destination: domain.Coordinates{Latitude: 7.8, Longitude: 123.4},
		Preference:  "fastest",
		Profile:     "driving",
		DistanceKm:  18.5,
		DurationMin: 27,
		Polyline:    [][]float64{{6.7, 122.1}, {7.8, 123.4}},
	})
	encodedRoute, err := json.Marshal(route)
	if err != nil {
		t.Fatalf("marshal route response: %v", err)
	}
	const wantRoute = `{"origin":{"lat":6.7,"lng":122.1},"destination":{"lat":7.8,"lng":123.4},"preference":"fastest","profile":"driving","distance_km":18.5,"duration_min":27,"polyline":[[6.7,122.1],[7.8,123.4]]}`
	if string(encodedRoute) != wantRoute {
		t.Fatalf("route response = %s, want %s", encodedRoute, wantRoute)
	}

	matrix := NewMatrixResponse(&domain.Matrix{DistancesKm: []float64{1.5}, DurationsMin: []float64{2.75}})
	encodedMatrix, err := json.Marshal(matrix)
	if err != nil {
		t.Fatalf("marshal matrix response: %v", err)
	}
	const wantMatrix = `{"distances_km":[1.5],"durations_min":[2.75]}`
	if string(encodedMatrix) != wantMatrix {
		t.Fatalf("matrix response = %s, want %s", encodedMatrix, wantMatrix)
	}
}

func TestNewPlaceResponsesPreservesNil(t *testing.T) {
	if NewPlaceResponses(nil) != nil {
		t.Fatal("nil places returned a non-nil response slice")
	}
	if NewPlaceResponse(nil) != nil {
		t.Fatal("nil place returned a non-nil response")
	}
}

func TestNewDriverLocationResponsePreservesPublicFields(t *testing.T) {
	point := trackingdomain.DriverPoint{
		DriverID:   "driver-7",
		Latitude:   6.7,
		Longitude:  122.1,
		ObservedAt: time.Date(2026, time.October, 12, 9, 0, 0, 0, time.UTC),
	}
	encoded, err := json.Marshal(NewDriverLocationResponse(point))
	if err != nil {
		t.Fatalf("marshal driver location response: %v", err)
	}
	const want = `{"driver_id":"driver-7","latitude":6.7,"longitude":122.1,"observed_at":"2026-10-12T09:00:00Z"}`
	if string(encoded) != want {
		t.Fatalf("driver location response = %s, want %s", encoded, want)
	}
}
