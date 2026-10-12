package application

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

type ridesRepositoryStub struct {
	ride          domain.Ride
	created       domain.Ride
	updated       domain.Ride
	updateNext    string
	hasActiveRide bool
}

var (
	_ ports.RideStore                  = (*ridesRepositoryStub)(nil)
	_ ports.PassengerActiveRideChecker = (*ridesRepositoryStub)(nil)
	_ ports.RideLifecycleStore         = (*ridesRepositoryStub)(nil)
	_ ports.SafetyReportStore          = (*ridesRepositoryStub)(nil)
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
	repository ports.RideStore,
	pricingConfig PricingConfig,
	publisher ports.EventPublisher,
	options ...RideServiceOption,
) *RideService {
	return NewRideService(
		RideServiceDependencies{
			Repository:     repository,
			PricingConfig:  pricingConfig,
			EventPublisher: publisher,
			DriverLocation: ports.DriverLocationReaderFunc(
				func(context.Context, int) (ports.DriverLocation, error) {
					return ports.DriverLocation{
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

func intPointer(value int) *int { return &value }
