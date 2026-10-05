package tracking

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

type locationRepositoryStub struct {
	driverPoint    domain.DriverPoint
	passengerPoint domain.DriverPoint
	nearby         []domain.DriverPoint
	upsertCalls    int
	removeCalls    int
	upsertErr      error
}

type driverPresenceStub struct {
	online bool
	err    error
}

func (stub driverPresenceStub) IsOnline(context.Context, string) (bool, error) {
	return stub.online, stub.err
}

type driverPresenceSequenceStub struct {
	results []bool
	calls   int
}

func (stub *driverPresenceSequenceStub) IsOnline(context.Context, string) (bool, error) {
	index := stub.calls
	if index >= len(stub.results) {
		index = len(stub.results) - 1
	}
	stub.calls++
	return stub.results[index], nil
}

func newLocationTrackingService(
	repository LocationStore,
	options ...Option,
) *LocationTrackingService {
	return NewLocationTrackingService(LocationTrackingDependencies{Repository: repository}, options...)
}

func (stub *locationRepositoryStub) Upsert(_ context.Context, point domain.DriverPoint) error {
	stub.upsertCalls++
	if stub.upsertErr != nil {
		return stub.upsertErr
	}
	stub.driverPoint = point
	return nil
}
func (stub *locationRepositoryStub) Remove(context.Context, string) error {
	stub.removeCalls++
	return nil
}
func (stub *locationRepositoryStub) Nearby(context.Context, float64, float64, float64) ([]domain.DriverPoint, error) {
	return stub.nearby, nil
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
	service := newLocationTrackingService(&locationRepositoryStub{})
	invalidLatitudeErr := service.Ingest(
		context.Background(),
		domain.DriverPoint{DriverID: "7", Latitude: 91, Longitude: 122},
	)
	if invalidLatitudeErr == nil {
		t.Fatal("expected invalid latitude to be rejected")
	}
	invalidLongitudeErr := service.Ingest(
		context.Background(),
		domain.DriverPoint{DriverID: "7", Latitude: 6.7, Longitude: 181},
	)
	if invalidLongitudeErr == nil {
		t.Fatal("expected invalid longitude to be rejected")
	}
}

func TestIngestRejectsLocationFromAnOfflineDriver(t *testing.T) {
	repository := &locationRepositoryStub{}
	service := newLocationTrackingService(
		repository,
		WithDriverPresence(driverPresenceStub{}),
	)

	err := service.Ingest(
		context.Background(),
		domain.DriverPoint{
			DriverID:  "driver-1",
			Latitude:  6.7,
			Longitude: 122.1,
		},
	)
	if !errors.Is(err, domain.ErrDriverOffline) {
		t.Fatalf("Ingest() error = %v, want offline driver error", err)
	}
	if repository.upsertCalls != 0 {
		t.Fatalf("Upsert() calls = %d, want 0", repository.upsertCalls)
	}
}

func TestIngestRemovesLocationWhenTheDriverGoesOfflineDuringPersistence(t *testing.T) {
	repository := &locationRepositoryStub{}
	presence := &driverPresenceSequenceStub{results: []bool{true, false}}
	service := newLocationTrackingService(
		repository,
		WithDriverPresence(presence),
	)

	err := service.Ingest(
		context.Background(),
		domain.DriverPoint{
			DriverID:  "driver-1",
			Latitude:  6.7,
			Longitude: 122.1,
		},
	)
	if !errors.Is(err, domain.ErrDriverOffline) {
		t.Fatalf("Ingest() error = %v, want offline driver error", err)
	}
	if repository.upsertCalls != 1 {
		t.Fatalf("Upsert() calls = %d, want 1", repository.upsertCalls)
	}
	if repository.removeCalls != 1 {
		t.Fatalf("Remove() calls = %d, want 1", repository.removeCalls)
	}
}

func TestIngestFailsClosedWhenDriverPresenceCannotBeRead(t *testing.T) {
	repository := &locationRepositoryStub{}
	service := newLocationTrackingService(
		repository,
		WithDriverPresence(driverPresenceStub{err: errors.New("database unavailable")}),
	)

	err := service.Ingest(
		context.Background(),
		domain.DriverPoint{
			DriverID:  "driver-1",
			Latitude:  6.7,
			Longitude: 122.1,
		},
	)
	if !errors.Is(err, domain.ErrDriverPresenceUnavailable) {
		t.Fatalf("Ingest() error = %v, want presence unavailable error", err)
	}
	if repository.upsertCalls != 0 {
		t.Fatalf("Upsert() calls = %d, want 0", repository.upsertCalls)
	}
}

func TestIngestIgnoresTelemetryOlderThanTheConfiguredFreshnessWindow(t *testing.T) {
	repository := &locationRepositoryStub{}
	service := NewLocationTrackingService(
		LocationTrackingDependencies{
			Repository: repository,
			MaxAge:     time.Minute,
		},
	)

	err := service.Ingest(
		context.Background(),
		domain.DriverPoint{
			DriverID:   "driver-1",
			Latitude:   6.7,
			Longitude:  122.1,
			ObservedAt: time.Now().UTC().Add(-time.Minute - time.Second),
		},
	)
	if err != nil {
		t.Fatalf("Ingest() error = %v, want nil for stale telemetry", err)
	}
	if repository.upsertCalls != 0 {
		t.Fatalf("Upsert() calls = %d, want 0", repository.upsertCalls)
	}
}

func TestIngestRejectsTelemetryBeyondTheAllowedClockSkew(t *testing.T) {
	repository := &locationRepositoryStub{}
	service := newLocationTrackingService(repository)

	err := service.Ingest(
		context.Background(),
		domain.DriverPoint{
			DriverID:   "driver-1",
			Latitude:   6.7,
			Longitude:  122.1,
			ObservedAt: time.Now().UTC().Add(16 * time.Second),
		},
	)
	if !errors.Is(err, domain.ErrInvalidLocation) {
		t.Fatalf("Ingest() error = %v, want invalid location", err)
	}
	if repository.upsertCalls != 0 {
		t.Fatalf("Upsert() calls = %d, want 0", repository.upsertCalls)
	}
}

func TestIngestStopsBeforePersistenceWhenContextIsCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	repository := &locationRepositoryStub{}
	service := newLocationTrackingService(repository)

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
	service := newLocationTrackingService(&locationRepositoryStub{})
	if _, err := service.Nearby(context.Background(), 6.7, 122.1, 0); err == nil {
		t.Fatal("expected zero radius to be rejected")
	}
	if _, err := service.Nearby(context.Background(), 6.7, 122.1, 51); err == nil {
		t.Fatal("expected oversized radius to be rejected")
	}
}

func TestNearbyReturnsACopyOfRepositoryResults(t *testing.T) {
	repository := &locationRepositoryStub{
		nearby: []domain.DriverPoint{{
			DriverID:   "driver-1",
			Latitude:   6.7006,
			Longitude:  122.1004,
			Heading:    120,
			Speed:      18,
			ObservedAt: time.Now().UTC(),
		}},
	}
	service := newLocationTrackingService(repository)

	points, err := service.Nearby(context.Background(), 6.7, 122.1, 5)
	if err != nil {
		t.Fatalf("Nearby() error = %v", err)
	}
	if points[0].Latitude != 6.701 || points[0].Longitude != 122.1 {
		t.Fatalf("Nearby() coordinates = (%v, %v), want rounded discovery coordinates", points[0].Latitude, points[0].Longitude)
	}
	if points[0].Heading != 0 || points[0].Speed != 0 || !points[0].ObservedAt.IsZero() {
		t.Fatalf("Nearby() exposed tracking metadata: %#v", points[0])
	}
	points[0].DriverID = "mutated"
	if repository.nearby[0].DriverID != "driver-1" {
		t.Fatalf("repository locations were mutated through returned points: %#v", repository.nearby)
	}
}

func TestIngestPublishesAnActiveRideLocationToBothParticipants(t *testing.T) {
	repository := &locationRepositoryStub{}
	publisher := &locationEventPublisherStub{}
	service := newLocationTrackingService(
		repository,
		WithRideAssignments(assignmentLookupStub{
			assignments: []assignment.Assignment{{
				RideID:      "ride-7",
				DriverID:    "driver-1",
				PassengerID: "passenger-2",
				Status:      "assigned",
			}},
		}),
		WithEventPublisher(publisher),
	)

	err := service.Ingest(
		context.Background(),
		domain.DriverPoint{DriverID: "driver-1", Latitude: 6.7, Longitude: 122.1},
	)
	if err != nil {
		t.Fatalf("Ingest() error = %v", err)
	}
	if len(publisher.envelopes) != 1 {
		t.Fatalf("published event count = %d, want 1", len(publisher.envelopes))
	}
	published := publisher.envelopes[0]
	if published.Type != event.DriverLocationUpdated {
		t.Fatalf("event type = %q", published.Type)
	}
	invalidRideID := published.Scope.RideID != "ride-7"
	invalidDriverID := published.Scope.DriverID != "driver-1"
	invalidPassengerID := published.Scope.PassengerID != "passenger-2"
	if invalidRideID || invalidDriverID || invalidPassengerID {
		t.Fatalf("event scope = %#v", published.Scope)
	}
}

func TestIngestIgnoresAStaleDriverLocation(t *testing.T) {
	repository := &locationRepositoryStub{upsertErr: domain.ErrStaleLocation}
	publisher := &locationEventPublisherStub{}
	service := newLocationTrackingService(
		repository,
		WithEventPublisher(publisher),
	)

	err := service.Ingest(
		context.Background(),
		domain.DriverPoint{DriverID: "driver-1", Latitude: 6.7, Longitude: 122.1},
	)
	if err != nil {
		t.Fatalf("Ingest() error = %v, want nil for a stale point", err)
	}
	if len(publisher.envelopes) != 0 {
		t.Fatalf("published event count = %d, want 0", len(publisher.envelopes))
	}
}

func TestPassengerLocationRequiresTheRidePassenger(t *testing.T) {
	service := newLocationTrackingService(
		&locationRepositoryStub{},
		WithRideAssignments(assignmentLookupStub{
			assignments: []assignment.Assignment{{
				RideID:      "ride-7",
				DriverID:    "driver-1",
				PassengerID: "passenger-2",
				Status:      "assigned",
			}},
		}),
	)

	err := service.UpdatePassenger(
		context.Background(),
		"ride-7",
		"passenger-3",
		domain.DriverPoint{Latitude: 6.7, Longitude: 122.1},
	)
	if !errors.Is(err, domain.ErrRideAccessDenied) {
		t.Fatalf("UpdatePassenger() error = %v, want access denied", err)
	}
}
