package application

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

type ridesRepositoryStub struct {
	ride          domain.Ride
	created       domain.Ride
	updated       domain.Ride
	session       domain.BidSession
	updateNext    string
	hasActiveRide bool
}

var (
	_ ports.RideStore                  = (*ridesRepositoryStub)(nil)
	_ ports.PassengerActiveRideChecker = (*ridesRepositoryStub)(nil)
	_ ports.BiddingStore               = (*ridesRepositoryStub)(nil)
	_ ports.RideLifecycleStore         = (*ridesRepositoryStub)(nil)
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

func (stub *ridesRepositoryStub) CreateSession(
	_ context.Context,
	session domain.BidSession,
) (domain.BidSession, error) {
	stub.session = session
	return session, nil
}

func (stub *ridesRepositoryStub) ActiveSessions(context.Context, *int) ([]domain.BidSession, error) {
	return nil, nil
}

func (stub *ridesRepositoryStub) Offers(context.Context, int) ([]domain.BidOffer, error) {
	return nil, nil
}

func (stub *ridesRepositoryStub) PlaceOffer(context.Context, domain.BidOffer) (domain.BidOffer, error) {
	return domain.BidOffer{}, nil
}

func (stub *ridesRepositoryStub) AcceptOffer(
	context.Context,
	int,
	int,
	int,
) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, nil
}

func (stub *ridesRepositoryStub) CancelSession(context.Context, int, int) (domain.BidSession, error) {
	return domain.BidSession{}, nil
}

func (stub *ridesRepositoryStub) CancelOffer(context.Context, int, int) (domain.BidOffer, error) {
	return domain.BidOffer{}, nil
}

func (stub *ridesRepositoryStub) Session(context.Context, int) (domain.BidSession, error) {
	return stub.session, nil
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

func TestCreateSessionUsesServerMinimumAndAcceptsValidCustomFare(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := newTestRideService(stub, testPricingConfig(t), nil)
	custom := int64(5000)
	session, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
		DistanceKm:       2,
		DurationMinutes:  10,
		CustomFareAmount: &custom,
	})
	if err != nil {
		t.Fatalf("CreateSession returned error: %v", err)
	}
	if session.OfferedFareAmount != custom || stub.session.OfferedFareAmount != custom {
		t.Fatalf("expected custom fare %d, got %d", custom, session.OfferedFareAmount)
	}
}

func TestCreateSessionUsesAuthoritativeRouteMetrics(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := newTestRideService(
		stub,
		testPricingConfig(t),
		nil,
		WithRouteCalculator(RouteCalculatorFunc(func(
			context.Context,
			float64,
			float64,
			float64,
			float64,
		) (RouteMetrics, error) {
			return RouteMetrics{DistanceKm: 4, DurationMinutes: 20}, nil
		})),
	)
	custom := int64(4000)
	session, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
		DistanceKm:       0.01,
		DurationMinutes:  0.01,
		CustomFareAmount: &custom,
	})
	if err != nil {
		t.Fatalf("CreateSession returned error: %v", err)
	}
	if session.DistanceKm != 4 || session.DurationMinutes != 20 {
		t.Fatalf("expected server route metrics, got %.2f km and %.2f minutes", session.DistanceKm, session.DurationMinutes)
	}
	if session.OfferedFareAmount != custom {
		t.Fatalf("expected custom fare %d, got %d", custom, session.OfferedFareAmount)
	}
}

func TestCreateSessionFailsWhenAuthoritativeRouteIsUnavailable(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := newTestRideService(
		stub,
		testPricingConfig(t),
		nil,
		WithRouteCalculator(RouteCalculatorFunc(func(
			context.Context,
			float64,
			float64,
			float64,
			float64,
		) (RouteMetrics, error) {
			return RouteMetrics{}, errors.New("mapbox timeout")
		})),
	)
	_, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
	})
	if !errors.Is(err, domain.ErrRouteUnavailable) {
		t.Fatalf("expected ErrRouteUnavailable, got %v", err)
	}
}

func TestCreateSessionPreservesRouteContextCancellation(t *testing.T) {
	stub := &ridesRepositoryStub{}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	service := newTestRideService(
		stub,
		testPricingConfig(t),
		nil,
		WithRouteCalculator(RouteCalculatorFunc(func(context.Context, float64, float64, float64, float64) (RouteMetrics, error) {
			cancel()
			return RouteMetrics{DistanceKm: 4, DurationMinutes: 20}, nil
		})),
	)

	_, err := service.CreateSession(ctx, domain.BidSession{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
	})
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context cancellation, got %v", err)
	}
	if stub.session.PassengerID != 0 {
		t.Fatalf("canceled route must not persist a session: %#v", stub.session)
	}
}

func TestCreateSessionRejectsOfferBelowCalculatedMinimum(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := newTestRideService(stub, testPricingConfig(t), nil)
	custom := int64(1)
	_, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
		DistanceKm:       2,
		DurationMinutes:  10,
		CustomFareAmount: &custom,
	})
	if !errors.Is(err, domain.ErrInvalidFareOffer) {
		t.Fatalf("expected ErrInvalidFareOffer, got %v", err)
	}
}

func TestCreateSessionRejectsPassengerWithActiveRide(t *testing.T) {
	stub := &ridesRepositoryStub{hasActiveRide: true}
	service := newTestRideService(stub, testPricingConfig(t), nil)
	_, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
		DistanceKm:       2,
		DurationMinutes:  10,
	})
	if !errors.Is(err, domain.ErrActiveBooking) {
		t.Fatalf("CreateSession error = %v, want %v", err, domain.ErrActiveBooking)
	}
	if stub.session.PassengerID != 0 {
		t.Fatal("expected bid session NOT to be persisted when passenger has an active ride")
	}
}

func TestCreateSessionRejectsPassengerWithActiveRideBeforeRouteCalculation(t *testing.T) {
	stub := &ridesRepositoryStub{hasActiveRide: true}
	routeResolved := false
	service := newTestRideService(
		stub,
		testPricingConfig(t),
		nil,
		WithRouteCalculator(RouteCalculatorFunc(func(
			context.Context,
			float64,
			float64,
			float64,
			float64,
		) (RouteMetrics, error) {
			routeResolved = true
			return RouteMetrics{DistanceKm: 4, DurationMinutes: 20}, nil
		})),
	)
	_, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
	})
	if !errors.Is(err, domain.ErrActiveBooking) {
		t.Fatalf("CreateSession error = %v, want %v", err, domain.ErrActiveBooking)
	}
	if routeResolved {
		t.Fatal("expected route calculator NOT to be called when passenger has an active ride")
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
