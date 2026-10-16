package app

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

type eventPublisherStub struct {
	events []RealtimeEvent
	err    error
}

func (stub *eventPublisherStub) Publish(_ context.Context, realtimeEvent RealtimeEvent) error {
	stub.events = append(stub.events, realtimeEvent)
	return stub.err
}

func TestStartTripPublishesToBothRideParticipants(t *testing.T) {
	repository := &ridesRepositoryStub{
		ride: domain.Ride{
			ID:              9,
			PassengerID:     7,
			DriverID:        intPointer(11),
			Status:          "arrived",
			PickupLatitude:  6.7,
			PickupLongitude: 122.1,
		},
	}
	publisher := &eventPublisherStub{}
	service := newTestRideService(repository, testPricingConfig(t), publisher)

	updated, err := service.StartTrip(context.Background(), 9, 11, 6.7, 122.1)
	if err != nil {
		t.Fatalf("StartTrip() error = %v", err)
	}
	if updated.Status != "in_transit" {
		t.Fatalf("updated status = %q, want in_transit", updated.Status)
	}
	if len(publisher.events) != 1 {
		t.Fatalf("published event count = %d, want 1", len(publisher.events))
	}
	published := publisher.events[0]
	if published.Type != event.RideStatusChanged {
		t.Fatalf("event type = %q, want %q", published.Type, event.RideStatusChanged)
	}
	if published.Scope.RideID != "9" || published.Scope.PassengerID != "7" || published.Scope.DriverID != "11" {
		t.Fatalf("event scope = %#v", published.Scope)
	}
}

func TestPublishingFailureDoesNotRollbackPersistedStatus(t *testing.T) {
	repository := &ridesRepositoryStub{
		ride: domain.Ride{
			ID:              9,
			PassengerID:     7,
			DriverID:        intPointer(11),
			Status:          "arrived",
			PickupLatitude:  6.7,
			PickupLongitude: 122.1,
		},
	}
	publisher := &eventPublisherStub{err: errors.New("redis unavailable")}
	service := newTestRideService(repository, testPricingConfig(t), publisher)

	updated, err := service.StartTrip(context.Background(), 9, 11, 6.7, 122.1)
	if err != nil {
		t.Fatalf("StartTrip() error = %v", err)
	}
	if updated.Status != "in_transit" || repository.updated.Status != "in_transit" {
		t.Fatalf("persisted update was rolled back: %#v", updated)
	}
}
