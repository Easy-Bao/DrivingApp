package tracking

import (
	"encoding/json"
	jsonv2 "encoding/json/v2"
	"reflect"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
)

func TestDriverLocationRecordPreservesRedisPayload(t *testing.T) {
	point := domain.DriverPoint{
		DriverID:   "driver-7",
		Latitude:   6.7,
		Longitude:  122.1,
		ObservedAt: time.Date(2026, time.October, 12, 9, 0, 0, 0, time.UTC),
	}
	payload, err := jsonv2.Marshal(newDriverLocationRecord(point))
	if err != nil {
		t.Fatalf("marshal driver location record: %v", err)
	}
	var fields map[string]any
	if err := json.Unmarshal(payload, &fields); err != nil {
		t.Fatalf("unmarshal driver location record: %v", err)
	}
	if len(fields) != 6 || fields["driver_id"] != "driver-7" ||
		fields["latitude"] != 6.7 || fields["longitude"] != 122.1 ||
		fields["heading"] != float64(0) || fields["speed"] != float64(0) ||
		fields["observed_at"] != "2026-10-12T09:00:00Z" {
		t.Fatalf("stored fields = %#v", fields)
	}

	var persisted driverLocationRecord
	if err := jsonv2.Unmarshal(payload, &persisted); err != nil {
		t.Fatalf("decode driver location record: %v", err)
	}
	if got := persisted.point(); !reflect.DeepEqual(got, point) {
		t.Fatalf("round-trip point = %#v, want %#v", got, point)
	}
}
