package redis

import (
	"encoding/json"
	"reflect"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
)

func TestPlaceCacheRecordPreservesExistingPayload(t *testing.T) {
	place := domain.Place{
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
	}
	payload, err := json.Marshal(newPlaceCacheRecord(place))
	if err != nil {
		t.Fatalf("marshal place cache record: %v", err)
	}
	const want = `{"id":"place.1","name":"Pagadian Terminal","address":"Pagadian City","category":"transport","lat":6.7,"lng":122.1,"distance_km":1.25,"match_type":"exact","distance_meters":1250,"confidence":0.97,"context":{"city":"Pagadian"}}`
	if string(payload) != want {
		t.Fatalf("place cache payload = %s, want %s", payload, want)
	}
	var persisted placeCacheRecord
	if err := json.Unmarshal(payload, &persisted); err != nil {
		t.Fatalf("unmarshal place cache record: %v", err)
	}
	if got := persisted.place(); !reflect.DeepEqual(got, place) {
		t.Fatalf("round-trip place = %#v, want %#v", got, place)
	}
}

func TestMatrixCacheRecordPreservesExistingPayload(t *testing.T) {
	matrix := &domain.Matrix{DistancesKm: []float64{1.25, 2.5}, DurationsMin: []float64{3, 7.5}}
	payload, err := json.Marshal(newMatrixCacheRecord(matrix))
	if err != nil {
		t.Fatalf("marshal matrix cache record: %v", err)
	}
	const want = `{"distances_km":[1.25,2.5],"durations_min":[3,7.5]}`
	if string(payload) != want {
		t.Fatalf("matrix cache payload = %s, want %s", payload, want)
	}
	var persisted matrixCacheRecord
	if err := json.Unmarshal(payload, &persisted); err != nil {
		t.Fatalf("unmarshal matrix cache record: %v", err)
	}
	if got := persisted.matrix(); !reflect.DeepEqual(got, matrix) {
		t.Fatalf("round-trip matrix = %#v, want %#v", got, matrix)
	}
}
