package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type eventPublisherStub struct {
	envelopes []event.Envelope
	err       error
}

func (stub *eventPublisherStub) Publish(_ context.Context, envelope event.Envelope) error {
	stub.envelopes = append(stub.envelopes, envelope)
	return stub.err
}

func TestUpdateStatusPublishesToBothRideParticipants(t *testing.T) {
	repository := &ridesRepositoryStub{
		ride: domain.Ride{ID: 9, PassengerID: 7, DriverID: intPointer(11), Status: "accepted"},
	}
	publisher := &eventPublisherStub{}
	service := NewService(repository, testPricingConfig(t), publisher)

	updated, err := service.UpdateStatus(context.Background(), 9, 11, "arrived")
	if err != nil {
		t.Fatalf("UpdateStatus() error = %v", err)
	}
	if updated.Status != "arrived" {
		t.Fatalf("updated status = %q, want arrived", updated.Status)
	}
	if len(publisher.envelopes) != 1 {
		t.Fatalf("published event count = %d, want 1", len(publisher.envelopes))
	}
	published := publisher.envelopes[0]
	if published.Type != event.RideStatusChanged {
		t.Fatalf("event type = %q, want %q", published.Type, event.RideStatusChanged)
	}
	if published.Scope.RideID != "9" || published.Scope.PassengerID != "7" || published.Scope.DriverID != "11" {
		t.Fatalf("event scope = %#v", published.Scope)
	}
}

func TestCreateSessionPublishesToPassengerAndTargetDriver(t *testing.T) {
	repository := &ridesRepositoryStub{}
	publisher := &eventPublisherStub{}
	service := NewService(repository, testPricingConfig(t), publisher)

	_, err := service.CreateSession(context.Background(), domain.BidSession{
		ID:             31,
		PassengerID:    7,
		TargetDriverID: intPointer(11),
		PickupLatitude: 6.7, PickupLongitude: 122.1,
		DropoffLatitude: 6.71, DropoffLongitude: 122.11,
		DistanceKm: 2, DurationMinutes: 10,
	})
	if err != nil {
		t.Fatalf("CreateSession() error = %v", err)
	}
	if len(publisher.envelopes) != 1 {
		t.Fatalf("published event count = %d, want 1", len(publisher.envelopes))
	}
	published := publisher.envelopes[0]
	if published.Type != event.RideOfferCreated {
		t.Fatalf("event type = %q, want %q", published.Type, event.RideOfferCreated)
	}
	if published.Scope.RideID != "" || published.Scope.PassengerID != "7" || published.Scope.DriverID != "11" {
		t.Fatalf("event scope = %#v", published.Scope)
	}
}

func TestPublishingFailureDoesNotRollbackPersistedStatus(t *testing.T) {
	repository := &ridesRepositoryStub{
		ride: domain.Ride{ID: 9, PassengerID: 7, DriverID: intPointer(11), Status: "accepted"},
	}
	publisher := &eventPublisherStub{err: errors.New("redis unavailable")}
	service := NewService(repository, testPricingConfig(t), publisher)

	updated, err := service.UpdateStatus(context.Background(), 9, 11, "arrived")
	if err != nil {
		t.Fatalf("UpdateStatus() error = %v", err)
	}
	if updated.Status != "arrived" || repository.updateNext != "arrived" {
		t.Fatalf("persisted update was rolled back: %#v", updated)
	}
}
