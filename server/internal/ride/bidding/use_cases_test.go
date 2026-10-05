package bidding_test

import (
	"context"
	"errors"
	"testing"
	"time"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/bidding"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

type biddingStoreStub struct {
	session    domain.BidSession
	offers     []domain.BidOffer
	acceptance domain.OfferAcceptance
	placeErr   error
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
	return stub.offers, nil
}
func (stub *biddingStoreStub) PlaceOffer(context.Context, domain.BidOffer) (domain.BidOffer, error) {
	return domain.BidOffer{}, stub.placeErr
}
func (stub *biddingStoreStub) AcceptOffer(
	context.Context,
	int,
	int,
	int,
) (domain.OfferAcceptance, error) {
	return stub.acceptance, nil
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

func TestCreateSessionUsesServerOwnedStatusAndExpiration(t *testing.T) {
	store := &biddingStoreStub{}
	now := time.Date(2026, time.October, 5, 10, 0, 0, 0, time.UTC)
	service := bidding.NewService(bidding.Dependencies{
		Store: store,
		ResolveRoute: func(
			context.Context,
			float64,
			float64,
			float64,
			float64,
			float64,
			float64,
		) (ports.RouteMetrics, error) {
			return ports.RouteMetrics{DistanceKm: 4, DurationMinutes: 12}, nil
		},
		CalculateFare: func(float64, float64) int64 { return 3500 },
		Config:        bidding.Config{SessionDuration: 90 * time.Second},
		Now:           func() time.Time { return now },
	})

	created, err := service.CreateSession(context.Background(), domain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
		Status:           "accepted",
		ExpiresAt:        now.Add(24 * time.Hour),
	})
	if err != nil {
		t.Fatalf("CreateSession() error = %v", err)
	}
	if created.Status != "open" {
		t.Fatalf("status = %q, want open", created.Status)
	}
	if want := now.Add(90 * time.Second); !created.ExpiresAt.Equal(want) {
		t.Fatalf("expiration = %v, want %v", created.ExpiresAt, want)
	}
}

func TestPlaceOfferRecoversAnIdempotentDuplicate(t *testing.T) {
	existing := domain.BidOffer{
		ID:                 7,
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 3500,
		Status:             "pending",
	}
	store := &biddingStoreStub{
		offers:   []domain.BidOffer{existing},
		placeErr: domain.ErrDuplicateBid,
	}
	service := bidding.NewService(bidding.Dependencies{Store: store})

	created, err := service.PlaceOffer(context.Background(), domain.BidOffer{
		SessionID:          existing.SessionID,
		DriverID:           existing.DriverID,
		ProposedFareAmount: existing.ProposedFareAmount,
	})
	if err != nil {
		t.Fatalf("PlaceOffer() error = %v", err)
	}
	if created != existing {
		t.Fatalf("recovered offer = %+v, want %+v", created, existing)
	}
}

func TestPlaceOfferKeepsDuplicateErrorForDifferentFare(t *testing.T) {
	store := &biddingStoreStub{
		offers: []domain.BidOffer{{
			SessionID:          10,
			DriverID:           42,
			ProposedFareAmount: 3500,
			Status:             "pending",
		}},
		placeErr: domain.ErrDuplicateBid,
	}
	service := bidding.NewService(bidding.Dependencies{Store: store})

	_, err := service.PlaceOffer(context.Background(), domain.BidOffer{
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 4000,
	})
	if !errors.Is(err, domain.ErrDuplicateBid) {
		t.Fatalf("PlaceOffer() error = %v, want %v", err, domain.ErrDuplicateBid)
	}
}

func TestAcceptOfferPublishesRideMatchedEvent(t *testing.T) {
	store := &biddingStoreStub{}
	var publishedType string
	service := bidding.NewService(bidding.Dependencies{
		Store: store,
		PublishRide: func(_ context.Context, eventType event.Type, _ domain.Ride, _ map[string]any) {
			publishedType = string(eventType)
		},
	})

	_, _, _, err := service.AcceptOffer(context.Background(), 10, 20, 101)
	if err != nil {
		t.Fatalf("AcceptOffer error = %v", err)
	}
	if publishedType != string(event.RideMatched) {
		t.Fatalf("published event = %q, want %q", publishedType, event.RideMatched)
	}
}

func TestAcceptOfferPublishesWithdrawnOutstandingOffers(t *testing.T) {
	withdrawnSession := domain.BidSession{ID: 33, PassengerID: 202}
	withdrawnOffer := domain.BidOffer{
		ID:        44,
		SessionID: withdrawnSession.ID,
		DriverID:  303,
		Status:    "rejected",
	}
	store := &biddingStoreStub{acceptance: domain.OfferAcceptance{
		Session: domain.BidSession{ID: 10, PassengerID: 101},
		Offer:   domain.BidOffer{ID: 20, SessionID: 10, DriverID: 303, Status: "accepted"},
		Ride:    domain.Ride{ID: 55, PassengerID: 101},
		WithdrawnOffers: []domain.BidOfferWithdrawal{
			{Session: withdrawnSession, Offer: withdrawnOffer},
		},
	}}
	var publishedSession domain.BidSession
	var publishedPayload map[string]any
	service := bidding.NewService(bidding.Dependencies{
		Store: store,
		PublishSession: func(
			_ context.Context,
			eventType event.Type,
			session domain.BidSession,
			payload map[string]any,
		) {
			if eventType != event.RideOfferUpdated {
				t.Fatalf("event type = %q, want %q", eventType, event.RideOfferUpdated)
			}
			publishedSession = session
			publishedPayload = payload
		},
	})

	if _, _, _, err := service.AcceptOffer(context.Background(), 10, 20, 101); err != nil {
		t.Fatalf("AcceptOffer() error = %v", err)
	}
	if publishedSession.ID != withdrawnSession.ID || publishedSession.PassengerID != withdrawnSession.PassengerID {
		t.Fatalf("published session = %+v", publishedSession)
	}
	if publishedPayload["offer"] != withdrawnOffer || publishedPayload["reason"] != "driver_unavailable" {
		t.Fatalf("published payload = %#v", publishedPayload)
	}
}

func TestSessionCopiesOffersAtTheApplicationBoundary(t *testing.T) {
	store := &biddingStoreStub{offers: []domain.BidOffer{{ID: 7, Status: "pending"}}}
	service := bidding.NewService(bidding.Dependencies{Store: store})

	session, err := service.Session(context.Background(), 10)
	if err != nil {
		t.Fatalf("Session() error = %v", err)
	}
	session.Offers[0].Status = "mutated"
	if store.offers[0].Status != "pending" {
		t.Fatalf("store offers were mutated through returned session: %#v", store.offers)
	}
}
