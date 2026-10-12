package dto

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
)

func TestNewDriverLocationResponsePreservesPublicFields(t *testing.T) {
	point := domain.DriverPoint{
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
