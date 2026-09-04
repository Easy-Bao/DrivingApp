package application

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

type locationRepositoryStub struct {
	driverPoint    domain.DriverPoint
	passengerPoint domain.DriverPoint
	upsertCalls    int
}

func (stub *locationRepositoryStub) Upsert(_ context.Context, point domain.DriverPoint) error {
	stub.upsertCalls++
	stub.driverPoint = point
	return nil
}
func (locationRepositoryStub) Remove(context.Context, string) error { return nil }
func (locationRepositoryStub) Nearby(context.Context, float64, float64, float64) ([]domain.DriverPoint, error) {
	return nil, nil
}
func (stub *locationRepositoryStub) Get(context.Context, string) (domain.DriverPoint, error) {
	return stub.driverPoint, nil
}
func (stub *locationRepositoryStub) UpsertPassenger(_ context.Context, _ string, point domain.DriverPoint) error {
	stub.passengerPoint = point
	return nil
}
func (stub *locationRepositoryStub) GetPassenger(context.Context, string) (domain.DriverPoint, error) {
	return stub.passengerPoint, nil
}

type assignmentLookupStub struct{ assignments []assignment.Assignment }

func (stub assignmentLookupStub) ForDriver(context.Context, string) ([]assignment.Assignment, error) {
	return stub.assignments, nil
}

func (stub assignmentLookupStub) ForRide(_ context.Context, rideID string) (assignment.Assignment, bool, error) {
	for _, value := range stub.assignments {
		if value.RideID == rideID {
			return value, true, nil
		}
	}
	return assignment.Assignment{}, false, nil
}

type locationEventPublisherStub struct{ envelopes []event.Envelope }

func (stub *locationEventPublisherStub) Publish(_ context.Context, envelope event.Envelope) error {
	stub.envelopes = append(stub.envelopes, envelope)
	return nil
}

func TestIngestRejectsInvalidCoordinates(t *testing.T) {
	service := NewLocationTrackingService(&locationRepositoryStub{})
	if err := service.Ingest(context.Background(), domain.DriverPoint{DriverID: "7", Latitude: 91, Longitude: 122}); err == nil {
		t.Fatal("expected invalid latitude to be rejected")
	}
	if err := service.Ingest(context.Background(), domain.DriverPoint{DriverID: "7", Latitude: 6.7, Longitude: 181}); err == nil {
		t.Fatal("expected invalid longitude to be rejected")
	}
}

func TestIngestStopsBeforePersistenceWhenContextIsCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	repository := &locationRepositoryStub{}
	service := NewLocationTrackingService(repository)

	err := service.Ingest(ctx, domain.DriverPoint{
		DriverID:  "driver-1",
		Latitude:  6.7,
		Longitude: 122.1,
	})
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("Ingest() error = %v, want context cancellation", err)
	}
	if repository.upsertCalls != 0 {
		t.Fatalf("Upsert() calls = %d, want 0", repository.upsertCalls)
	}
}

func TestNearbyRejectsUnboundedRadius(t *testing.T) {
	service := NewLocationTrackingService(&locationRepositoryStub{})
	if _, err := service.Nearby(context.Background(), 6.7, 122.1, 0); err == nil {
		t.Fatal("expected zero radius to be rejected")
	}
	if _, err := service.Nearby(context.Background(), 6.7, 122.1, 51); err == nil {
		t.Fatal("expected oversized radius to be rejected")
	}
}

func TestIngestPublishesAnActiveRideLocationToBothParticipants(t *testing.T) {
	repository := &locationRepositoryStub{}
	publisher := &locationEventPublisherStub{}
	service := NewLocationTrackingService(
		repository,
		WithRideAssignments(assignmentLookupStub{assignments: []assignment.Assignment{{RideID: "ride-7", DriverID: "driver-1", PassengerID: "passenger-2", Status: "assigned"}}}),
		WithEventPublisher(publisher),
	)

	if err := service.Ingest(context.Background(), domain.DriverPoint{DriverID: "driver-1", Latitude: 6.7, Longitude: 122.1}); err != nil {
		t.Fatalf("Ingest() error = %v", err)
	}
	if len(publisher.envelopes) != 1 {
		t.Fatalf("published event count = %d, want 1", len(publisher.envelopes))
	}
	published := publisher.envelopes[0]
	if published.Type != event.DriverLocationUpdated {
		t.Fatalf("event type = %q", published.Type)
	}
	if published.Scope.RideID != "ride-7" || published.Scope.DriverID != "driver-1" || published.Scope.PassengerID != "passenger-2" {
		t.Fatalf("event scope = %#v", published.Scope)
	}
}

func TestPassengerLocationRequiresTheRidePassenger(t *testing.T) {
	service := NewLocationTrackingService(
		&locationRepositoryStub{},
		WithRideAssignments(assignmentLookupStub{assignments: []assignment.Assignment{{RideID: "ride-7", DriverID: "driver-1", PassengerID: "passenger-2", Status: "assigned"}}}),
	)

	err := service.UpdatePassenger(context.Background(), "ride-7", "passenger-3", domain.DriverPoint{Latitude: 6.7, Longitude: 122.1})
	if !errors.Is(err, domain.ErrRideAccessDenied) {
		t.Fatalf("UpdatePassenger() error = %v, want access denied", err)
	}
}
