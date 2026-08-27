package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type ridesRepositoryStub struct {
	ride       domain.Ride
	created    domain.Ride
	updated    domain.Ride
	session    domain.BidSession
	updateNext string
}

func testPricingConfig(t *testing.T) PricingConfig {
	t.Helper()
	config, err := LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	return config
}

func (stub *ridesRepositoryStub) CreateRide(_ context.Context, ride domain.Ride) (domain.Ride, error) {
	stub.created = ride
	stub.created.ID = 12
	return stub.created, nil
}

func (stub *ridesRepositoryStub) CreateBid(context.Context, domain.Bid) (domain.Bid, error) {
	return domain.Bid{}, nil
}

func (stub *ridesRepositoryStub) AcceptBid(context.Context, int, int) (domain.Bid, domain.Ride, error) {
	return domain.Bid{}, domain.Ride{}, nil
}

func (stub *ridesRepositoryStub) Get(context.Context, int) (domain.Ride, error) {
	return stub.ride, nil
}

func (stub *ridesRepositoryStub) AcceptRide(context.Context, int, int) (domain.Ride, error) {
	return domain.Ride{}, nil
}

func (stub *ridesRepositoryStub) UpdateStatus(_ context.Context, _ int, _ int, currentStatus, nextStatus string) (domain.Ride, error) {
	if currentStatus != stub.ride.Status {
		return domain.Ride{}, errors.New("stale ride")
	}
	stub.updateNext = nextStatus
	stub.updated = stub.ride
	stub.updated.Status = nextStatus
	return stub.updated, nil
}

func (stub *ridesRepositoryStub) CreateSession(_ context.Context, session domain.BidSession) (domain.BidSession, error) {
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

func (stub *ridesRepositoryStub) AcceptOffer(context.Context, int, int, int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
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
	service := NewRideService(stub, testPricingConfig(t))

	ride, err := service.CreateRide(context.Background(), 2, 2500)
	if err != nil {
		t.Fatalf("CreateRide returned error: %v", err)
	}
	if ride.ID != 12 {
		t.Fatalf("created ride id = %d, want 12", ride.ID)
	}
	if stub.created.PassengerID != 2 || stub.created.FareCentavos != 2500 ||
		stub.created.Status != "requested" || stub.created.RideType != "Solo Ride" {
		t.Fatalf("persisted ride = %#v", stub.created)
	}
}

func TestCreateSessionUsesServerMinimumAndAcceptsValidCustomFare(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := NewRideService(stub, testPricingConfig(t))
	custom := int64(5000)
	session, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:        7,
		PickupLatitude:     6.7,
		PickupLongitude:    122.1,
		DropoffLatitude:    6.71,
		DropoffLongitude:   122.11,
		DistanceKm:         2,
		DurationMinutes:    10,
		CustomFareCentavos: &custom,
	})
	if err != nil {
		t.Fatalf("CreateSession returned error: %v", err)
	}
	if session.OfferedFareCentavos != custom || stub.session.OfferedFareCentavos != custom {
		t.Fatalf("expected custom fare %d, got %d", custom, session.OfferedFareCentavos)
	}
}

func TestCreateSessionUsesAuthoritativeRouteMetrics(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := NewRideServiceWithRouteCalculator(stub, RouteCalculatorFunc(func(context.Context, float64, float64, float64, float64) (RouteMetrics, error) {
		return RouteMetrics{DistanceKm: 4, DurationMinutes: 20}, nil
	}), testPricingConfig(t))
	custom := int64(4000)
	session, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:        7,
		PickupLatitude:     6.7,
		PickupLongitude:    122.1,
		DropoffLatitude:    6.71,
		DropoffLongitude:   122.11,
		DistanceKm:         0.01,
		DurationMinutes:    0.01,
		CustomFareCentavos: &custom,
	})
	if err != nil {
		t.Fatalf("CreateSession returned error: %v", err)
	}
	if session.DistanceKm != 4 || session.DurationMinutes != 20 {
		t.Fatalf("expected server route metrics, got %.2f km and %.2f minutes", session.DistanceKm, session.DurationMinutes)
	}
	if session.OfferedFareCentavos != custom {
		t.Fatalf("expected custom fare %d, got %d", custom, session.OfferedFareCentavos)
	}
}

func TestCreateSessionFailsWhenAuthoritativeRouteIsUnavailable(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := NewRideServiceWithRouteCalculator(stub, RouteCalculatorFunc(func(context.Context, float64, float64, float64, float64) (RouteMetrics, error) {
		return RouteMetrics{}, errors.New("mapbox timeout")
	}), testPricingConfig(t))
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

func TestCreateSessionRejectsOfferBelowCalculatedMinimum(t *testing.T) {
	stub := &ridesRepositoryStub{}
	service := NewRideService(stub, testPricingConfig(t))
	custom := int64(1)
	_, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:        7,
		PickupLatitude:     6.7,
		PickupLongitude:    122.1,
		DropoffLatitude:    6.71,
		DropoffLongitude:   122.11,
		DistanceKm:         2,
		DurationMinutes:    10,
		CustomFareCentavos: &custom,
	})
	if !errors.Is(err, domain.ErrInvalidFareOffer) {
		t.Fatalf("expected ErrInvalidFareOffer, got %v", err)
	}
}

func TestUpdateStatusRequiresRideParticipantAndCurrentState(t *testing.T) {
	stub := &ridesRepositoryStub{ride: domain.Ride{ID: 9, PassengerID: 7, DriverID: intPointer(11), Status: "accepted"}}
	service := NewRideService(stub, testPricingConfig(t))
	if _, err := service.UpdateStatus(context.Background(), 9, 99, "arrived"); !errors.Is(err, domain.ErrUnauthorizedRide) {
		t.Fatalf("expected unauthorized ride error, got %v", err)
	}
	if _, err := service.UpdateStatus(context.Background(), 9, 7, "arrived"); !errors.Is(err, domain.ErrUnauthorizedRide) {
		t.Fatalf("expected passenger transition rejection, got %v", err)
	}
	if _, err := service.UpdateStatus(context.Background(), 9, 11, "arrived"); err != nil {
		t.Fatalf("expected driver transition to succeed, got %v", err)
	}
	if stub.updateNext != "arrived" {
		t.Fatalf("expected persisted arrived status, got %q", stub.updateNext)
	}
}

func TestUpdateStatusAllowsLegacyAssignedRideToReachPickup(t *testing.T) {
	stub := &ridesRepositoryStub{ride: domain.Ride{ID: 10, PassengerID: 7, DriverID: intPointer(11), Status: "assigned"}}
	service := NewRideService(stub, testPricingConfig(t))

	if _, err := service.UpdateStatus(context.Background(), 10, 11, "arrived"); err != nil {
		t.Fatalf("expected legacy assigned ride to reach pickup, got %v", err)
	}
	if stub.updateNext != "arrived" {
		t.Fatalf("expected persisted arrived status, got %q", stub.updateNext)
	}
}

func TestCalculateFareRejectsNonFiniteInput(t *testing.T) {
	service := NewRideService(nil, testPricingConfig(t))
	if got := service.CalculateFare(-1, 2); got != 0 {
		t.Fatalf("expected invalid fare to be zero, got %d", got)
	}
	if got := service.CalculateFare(0, 0); got != 2500 {
		t.Fatalf("expected minimum fare, got %d", got)
	}
}

func intPointer(value int) *int { return &value }
