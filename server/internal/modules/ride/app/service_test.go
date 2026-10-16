package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

type ridesRepositoryStub struct {
	ride             domain.Ride
	created          domain.Ride
	updated          domain.Ride
	updateNext       string
	hasActiveRide    bool
	driverTrips      []domain.Ride
	lastHistoryQuery domain.TripHistoryQuery
}

var (
	_ RideStore                  = (*ridesRepositoryStub)(nil)
	_ PassengerActiveRideChecker = (*ridesRepositoryStub)(nil)
	_ RideLifecycleStore         = (*ridesRepositoryStub)(nil)
	_ SafetyReportStore          = (*ridesRepositoryStub)(nil)
	_ RideHistoryReader          = (*ridesRepositoryStub)(nil)
)

func testPricingConfig(t *testing.T) PricingConfig {
	t.Helper()
	return PricingConfig{
		BaseFareAmount:        2500,
		PerKilometerAmount:    100,
		PerMinuteAmount:       50,
		PlatformCommissionBPS: 1500,
		RatingPricingConfig: RatingPricingConfig{
			MinimumRatingThreshold:          4.5,
			HighRatingBonusMultiplier:       1.05,
			LowRatingSurgePenaltyMultiplier: 1,
			BaseSurgeCap:                    2.5,
		},
	}
}

func newTestRideService(
	repository RideStore,
	pricingConfig PricingConfig,
	publisher EventPublisher,
	options ...RideServiceOption,
) *RideService {
	return NewRideService(
		RideServiceDependencies{
			Repository:     repository,
			PricingConfig:  pricingConfig,
			EventPublisher: publisher,
			DriverLocation: DriverLocationReaderFunc(
				func(context.Context, int) (DriverLocation, error) {
					return DriverLocation{
						Latitude:   6.7,
						Longitude:  122.1,
						ObservedAt: time.Now().UTC(),
					}, nil
				},
			),
		},
		options...,
	)
}

func (stub *ridesRepositoryStub) CreateRide(_ context.Context, ride domain.Ride) (domain.Ride, error) {
	stub.created = ride
	stub.created.ID = 12
	return stub.created, nil
}

func (stub *ridesRepositoryStub) Get(context.Context, int) (domain.Ride, error) {
	return stub.ride, nil
}

func (stub *ridesRepositoryStub) HasActivePassengerRide(_ context.Context, _ int) (bool, error) {
	return stub.hasActiveRide, nil
}

func (stub *ridesRepositoryStub) AcceptRide(context.Context, int, int) (domain.Ride, error) {
	return domain.Ride{}, nil
}

func (stub *ridesRepositoryStub) MarkArrived(
	_ context.Context,
	_ int,
	_ int,
	_ string,
	_ time.Duration,
) (domain.Ride, error) {
	stub.updated = stub.ride
	stub.updated.Status = "arrived"
	return stub.updated, nil
}

func (stub *ridesRepositoryStub) MarkPassengerNoShow(
	_ context.Context,
	_ int,
	_ int,
) (domain.Ride, error) {
	stub.updated = stub.ride
	stub.updated.Status = "cancelled"
	return stub.updated, nil
}

func (stub *ridesRepositoryStub) StartTrip(
	_ context.Context,
	_ int,
	_ int,
) (domain.Ride, error) {
	stub.updated = stub.ride
	stub.updated.Status = "in_transit"
	return stub.updated, nil
}

func (stub *ridesRepositoryStub) CompleteTrip(
	_ context.Context,
	_ int,
	_ int,
) (domain.Ride, error) {
	stub.updated = stub.ride
	stub.updated.Status = "completed"
	return stub.updated, nil
}

func (stub *ridesRepositoryStub) CreateSafetyReport(
	_ context.Context,
	report domain.SafetyReport,
) (domain.SafetyReport, error) {
	report.ID = 21
	report.Status = domain.SafetyReportSubmitted
	return report, nil
}

func (stub *ridesRepositoryStub) UpdateStatus(
	_ context.Context,
	_ int,
	_ int,
	currentStatus string,
	nextStatus string,
	_ domain.RideTransition,
) (domain.Ride, error) {
	if currentStatus != stub.ride.Status {
		return domain.Ride{}, errors.New("stale ride")
	}
	stub.updateNext = nextStatus
	stub.updated = stub.ride
	stub.updated.Status = nextStatus
	return stub.updated, nil
}

func (stub *ridesRepositoryStub) DriverTrips(
	_ context.Context,
	_ int,
	query domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	stub.lastHistoryQuery = query
	var matched []domain.Ride
	for _, ride := range stub.driverTrips {
		if query.ActiveOnly {
			if ride.Status == "assigned" || ride.Status == "accepted" || ride.Status == "arrived" || ride.Status == "in_transit" {
				matched = append(matched, ride)
			}
		} else {
			if ride.Status == "completed" || ride.Status == "cancelled" {
				matched = append(matched, ride)
			}
		}
	}
	return matched, nil
}

func (stub *ridesRepositoryStub) PassengerRides(
	_ context.Context,
	_ int,
	_ domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	return nil, nil
}

func TestCreateRideBuildsRequestedRide(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := newTestRideService(stub, testPricingConfig(t), nil)

	ride, err := service.CreateRide(context.Background(), 2, 2500)
	if err != nil {
		t.Fatalf("CreateRide returned error: %v", err)
	}
	if ride.ID != 12 {
		t.Fatalf("created ride id = %d, want 12", ride.ID)
	}
	if stub.created.PassengerID != 2 || stub.created.FareAmount != 2500 ||
		stub.created.Status != "requested" || stub.created.RideType != "Solo Ride" {
		t.Fatalf("persisted ride = %#v", stub.created)
	}
}

func TestCreateSafetyReportNormalizesAndDerivesSeverity(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := newTestRideService(stub, testPricingConfig(t), nil)
	report, err := service.CreateSafetyReport(context.Background(), domain.SafetyReport{
		RideID:       12,
		ReporterID:   7,
		ReporterRole: " PASSENGER ",
		Category:     " UNSAFE_DRIVING ",
		Severity:     domain.SafetyReportCritical,
		Description:  "The driver was driving dangerously near the market.",
	})
	if err != nil {
		t.Fatalf("CreateSafetyReport returned error: %v", err)
	}
	if report.ReporterRole != "passenger" || report.Category != domain.SafetyReportUnsafeDriving ||
		report.Severity != domain.SafetyReportHigh || report.Status != domain.SafetyReportSubmitted {
		t.Fatalf("created report = %+v", report)
	}
}

func TestStartTripRequiresRideParticipantAndCurrentState(t *testing.T) {
	stub := &ridesRepositoryStub{ride: domain.Ride{
		ID:              9,
		PassengerID:     7,
		DriverID:        intPointer(11),
		Status:          "arrived",
		PickupLatitude:  6.7,
		PickupLongitude: 122.1,
	}}
	service := newTestRideService(stub, testPricingConfig(t), nil)
	if _, err := service.StartTrip(
		context.Background(),
		9,
		99,
		6.7,
		122.1,
	); !errors.Is(err, domain.ErrUnauthorizedRide) {
		t.Fatalf("expected unauthorized ride error, got %v", err)
	}
	if _, err := service.StartTrip(context.Background(), 9, 7, 6.7, 122.1); !errors.Is(err, domain.ErrUnauthorizedRide) {
		t.Fatalf("expected passenger transition rejection, got %v", err)
	}
	if _, err := service.StartTrip(context.Background(), 9, 11, 6.7, 122.1); err != nil {
		t.Fatalf("expected driver transition to succeed, got %v", err)
	}
	if stub.updated.Status != "in_transit" {
		t.Fatalf("expected persisted in-transit status, got %q", stub.updated.Status)
	}
}

func TestUpdateStatusRequiresArrivalCommandForLegacyAssignedRide(t *testing.T) {
	stub := &ridesRepositoryStub{ride: domain.Ride{ID: 10, PassengerID: 7, DriverID: intPointer(11), Status: "assigned"}}
	service := newTestRideService(stub, testPricingConfig(t), nil)

	if _, err := service.UpdateStatus(context.Background(), 10, 11, "arrived"); !errors.Is(err, domain.ErrArrivalCommand) {
		t.Fatalf("expected arrival command requirement, got %v", err)
	}
	if stub.updateNext != "" {
		t.Fatalf("expected legacy assigned ride not to be persisted, got %q", stub.updateNext)
	}
}

func TestUpdateStatusRequiresCancellationCommandAfterRideCompletion(t *testing.T) {
	stub := &ridesRepositoryStub{
		ride: domain.Ride{ID: 11, PassengerID: 7, DriverID: intPointer(11), Status: "completed"},
	}
	service := newTestRideService(stub, testPricingConfig(t), nil)

	if _, err := service.UpdateStatus(context.Background(), 11, 11, "cancelled"); !errors.Is(err, domain.ErrCancellationCommand) {
		t.Fatalf("expected completed ride cancellation command error, got %v", err)
	}
	if stub.updateNext != "" {
		t.Fatalf("expected completed ride not to be persisted as cancelled, got %q", stub.updateNext)
	}
}

func TestUpdateStatusRequiresCancellationCommandAfterTripStartForPassenger(t *testing.T) {
	stub := &ridesRepositoryStub{
		ride: domain.Ride{ID: 12, PassengerID: 7, DriverID: intPointer(11), Status: "in_transit"},
	}
	service := newTestRideService(stub, testPricingConfig(t), nil)

	if _, err := service.UpdateStatus(context.Background(), 12, 7, "cancelled"); !errors.Is(err, domain.ErrCancellationCommand) {
		t.Fatalf("expected passenger cancellation command error, got %v", err)
	}
	if stub.updateNext != "" {
		t.Fatalf("expected in-transit ride not to be persisted as cancelled, got %q", stub.updateNext)
	}
}

func TestUpdateStatusRequiresCancellationCommandAfterTripStartForDriver(t *testing.T) {
	stub := &ridesRepositoryStub{
		ride: domain.Ride{ID: 13, PassengerID: 7, DriverID: intPointer(11), Status: "in_transit"},
	}
	service := newTestRideService(stub, testPricingConfig(t), nil)

	if _, err := service.UpdateStatus(context.Background(), 13, 11, "cancelled"); !errors.Is(err, domain.ErrCancellationCommand) {
		t.Fatalf("expected driver cancellation command error, got %v", err)
	}
	if stub.updateNext != "" {
		t.Fatalf("expected in-transit ride not to be persisted as cancelled, got %q", stub.updateNext)
	}
}

func TestCalculateFareRejectsNonFiniteInput(t *testing.T) {
	service := newTestRideService(nil, testPricingConfig(t), nil)
	if got := service.CalculateFare(-1, 2); got != 0 {
		t.Fatalf("expected invalid fare to be zero, got %d", got)
	}
	if got := service.CalculateFare(0, 0); got != 2500 {
		t.Fatalf("expected minimum fare, got %d", got)
	}
}

func TestDriverTripsQuarantinesActiveRidesFromHistory(t *testing.T) {
	stub := &ridesRepositoryStub{
		driverTrips: []domain.Ride{
			{ID: 1, Status: "in_transit", DriverID: intPointer(11)},
			{ID: 2, Status: "assigned", DriverID: intPointer(11)},
			{ID: 3, Status: "completed", DriverID: intPointer(11)},
			{ID: 4, Status: "cancelled", DriverID: intPointer(11)},
		},
	}
	service := newTestRideService(stub, testPricingConfig(t), nil)

	// Historical archive (ActiveOnly = false): must only contain terminal trips (completed, cancelled)
	historyTrips, err := service.DriverTrips(context.Background(), 11, domain.TripHistoryQuery{
		Limit:      10,
		Offset:     0,
		ActiveOnly: false,
	})
	if err != nil {
		t.Fatalf("DriverTrips history query returned error: %v", err)
	}
	if len(historyTrips) != 2 {
		t.Fatalf("got %d history trips, want 2", len(historyTrips))
	}
	for _, ride := range historyTrips {
		if ride.Status != "completed" && ride.Status != "cancelled" {
			t.Fatalf("unexpected non-terminal ride in history archive: %v", ride)
		}
	}

	// Active dispatch query (ActiveOnly = true): must only contain active trips (in_transit, assigned)
	activeTrips, err := service.DriverTrips(context.Background(), 11, domain.TripHistoryQuery{
		Limit:      10,
		Offset:     0,
		ActiveOnly: true,
	})
	if err != nil {
		t.Fatalf("DriverTrips active query returned error: %v", err)
	}
	if len(activeTrips) != 2 {
		t.Fatalf("got %d active trips, want 2", len(activeTrips))
	}
	for _, ride := range activeTrips {
		if ride.Status != "in_transit" && ride.Status != "assigned" {
			t.Fatalf("unexpected non-active ride in active query: %v", ride)
		}
	}
}

func TestDriverTripsValidatesPaginationBounds(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := newTestRideService(stub, testPricingConfig(t), nil)

	if _, err := service.DriverTrips(context.Background(), 11, domain.TripHistoryQuery{Limit: 0}); err == nil {
		t.Fatal("expected error for non-positive limit")
	}
	if _, err := service.DriverTrips(context.Background(), 11, domain.TripHistoryQuery{Limit: 10, Offset: -1}); err == nil {
		t.Fatal("expected error for negative offset")
	}
}

func intPointer(value int) *int { return &value }
