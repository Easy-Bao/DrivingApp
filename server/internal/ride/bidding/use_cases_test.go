package bidding_test

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/bidding"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

type biddingStoreStub struct {
	session domain.BidSession
}

func (stub *biddingStoreStub) CreateSession(_ context.Context, session domain.BidSession) (domain.BidSession, error) {
	stub.session = session
	stub.session.ID = 55
	return stub.session, nil
}
func (stub *biddingStoreStub) ActiveSessions(context.Context, *int) ([]domain.BidSession, error) {
	return nil, nil
}
func (stub *biddingStoreStub) Offers(context.Context, int) ([]domain.BidOffer, error) {
	return nil, nil
}
func (stub *biddingStoreStub) PlaceOffer(context.Context, domain.BidOffer) (domain.BidOffer, error) {
	return domain.BidOffer{}, nil
}
func (stub *biddingStoreStub) AcceptOffer(
	context.Context,
	int,
	int,
	int,
) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, nil
}
func (stub *biddingStoreStub) CancelSession(context.Context, int, int) (domain.BidSession, error) {
	return domain.BidSession{}, nil
}
func (stub *biddingStoreStub) CancelOffer(context.Context, int, int) (domain.BidOffer, error) {
	return domain.BidOffer{}, nil
}
func (stub *biddingStoreStub) Session(context.Context, int) (domain.BidSession, error) {
	return domain.BidSession{}, nil
}

type activeRideCheckerStub struct {
	hasActive bool
	err       error
	checkedID int
}

func (stub *activeRideCheckerStub) HasActivePassengerRide(_ context.Context, passengerID int) (bool, error) {
	stub.checkedID = passengerID
	return stub.hasActive, stub.err
}

func TestCreateSessionRejectsPassengerWithActiveRide(t *testing.T) {
	store := &biddingStoreStub{}
	checker := &activeRideCheckerStub{hasActive: true}
	routeResolved := false
	fareCalculated := false

	service := bidding.NewService(bidding.Dependencies{
		Store:             store,
		ActiveRideChecker: checker,
		ResolveRoute: func(
			context.Context,
			float64,
			float64,
			float64,
			float64,
			float64,
			float64,
		) (ports.RouteMetrics, error) {
			routeResolved = true
			return ports.RouteMetrics{DistanceKm: 5, DurationMinutes: 15}, nil
		},
		CalculateFare: func(float64, float64) int64 {
			fareCalculated = true
			return 3500
		},
	})

	_, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
	})
	if !errors.Is(err, domain.ErrActiveBooking) {
		t.Fatalf("CreateSession error = %v, want %v", err, domain.ErrActiveBooking)
	}
	if checker.checkedID != 101 {
		t.Fatalf("checked passenger ID = %d, want 101", checker.checkedID)
	}
	if routeResolved {
		t.Fatal("expected route resolution NOT to run when passenger has an active ride")
	}
	if fareCalculated {
		t.Fatal("expected fare calculation NOT to run when passenger has an active ride")
	}
	if store.session.ID != 0 {
		t.Fatal("expected session NOT to be persisted when passenger has an active ride")
	}
}
