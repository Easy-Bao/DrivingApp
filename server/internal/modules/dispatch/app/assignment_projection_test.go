package app

import (
	"context"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
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
	projection.Remember("driver-1", []Assignment{
		{RideID: "stale", DriverID: "driver-1", PassengerID: "passenger-1", Status: "assigned"},
	})
	projection.Remember("driver-1", []Assignment{
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

func TestMemoryProjectionExcludesNonActiveAndRemovesNoShow(t *testing.T) {
	projection := NewMemoryProjection()
	projection.Remember("driver-1", []Assignment{
		{RideID: "active-1", DriverID: "driver-1", PassengerID: "p-1", Status: "accepted"},
		{RideID: "done-1", DriverID: "driver-1", PassengerID: "p-2", Status: "completed", ContactOpen: true},
		{RideID: "cancelled-1", DriverID: "driver-1", PassengerID: "p-3", Status: "cancelled"},
	})
	values, err := projection.ForDriver(context.Background(), "driver-1")
	if err != nil || len(values) != 1 || values[0].RideID != "active-1" {
		t.Fatalf("ForDriver() = %#v, %v; want only active-1", values, err)
	}

	// Replayed RideMatched with terminal status must not enter the projection.
	terminalMatch, err := event.New(
		"replayed-match",
		event.RideMatched,
		time.Now().UTC(),
		event.Scope{RideID: "done-2", DriverID: "driver-1", PassengerID: "p-4"},
		map[string]any{"ride": map[string]any{"status": "completed"}},
	)
	if err != nil {
		t.Fatal(err)
	}
	projection.Publish(terminalMatch)
	if _, found, err := projection.ForRide(context.Background(), "done-2"); err != nil || found {
		t.Fatalf("terminal RideMatched leaked into projection: found=%t err=%v", found, err)
	}

	// no_show transition must evict the active ride.
	noShow, err := event.New(
		"no-show",
		event.RideStatusChanged,
		time.Now().UTC(),
		event.Scope{RideID: "active-1", DriverID: "driver-1", PassengerID: "p-1"},
		map[string]any{"ride": map[string]any{"status": "no_show"}},
	)
	if err != nil {
		t.Fatal(err)
	}
	projection.Publish(noShow)
	if _, found, err := projection.ForRide(context.Background(), "active-1"); err != nil || found {
		t.Fatalf("no_show ride remained in projection: found=%t err=%v", found, err)
	}
}
