package adapter

import (
	"context"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

func TestMemoryProjectionTracksActiveRideAssignments(t *testing.T) {
	projection := NewMemoryProjection()
	scope := event.Scope{RideID: "ride-1", DriverID: "driver-1", PassengerID: "passenger-1"}

	matched, err := event.New("matched", event.RideMatched, time.Now().UTC(), scope, map[string]any{})
	if err != nil {
		t.Fatal(err)
	}
	projection.Publish(matched)
	values, err := projection.ForDriver(context.Background(), "driver-1")
	if err != nil || len(values) != 1 || values[0].Status != "assigned" {
		t.Fatalf("ForDriver() = %#v, %v", values, err)
	}

	completed, err := event.New(
		"completed",
		event.RideStatusChanged,
		time.Now().UTC(),
		scope,
		map[string]any{"ride": map[string]any{"status": "completed"}},
	)
	if err != nil {
		t.Fatal(err)
	}
	projection.Publish(completed)
	values, err = projection.ForDriver(context.Background(), "driver-1")
	if err != nil || len(values) != 0 {
		t.Fatalf("completed ForDriver() = %#v, %v", values, err)
	}
}

func TestMemoryProjectionRememberRefreshesOneDriver(t *testing.T) {
	projection := NewMemoryProjection()
	projection.Remember("driver-1", []assignment.Assignment{
		{RideID: "stale", DriverID: "driver-1", PassengerID: "passenger-1", Status: "assigned"},
	})
	projection.Remember("driver-1", []assignment.Assignment{
		{RideID: "current", DriverID: "driver-1", PassengerID: "passenger-2", Status: "arrived"},
	})

	values, err := projection.ForDriver(context.Background(), "driver-1")
	if err != nil || len(values) != 1 || values[0].RideID != "current" {
		t.Fatalf("refreshed assignments = %#v, %v", values, err)
	}
	if _, found, err := projection.ForRide(context.Background(), "stale"); err != nil || found {
		t.Fatalf("stale assignment = found %t, error %v", found, err)
	}
}
