package application_test

import (
	"context"
	"errors"
	"testing"
	"time"

	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/application"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
	dispatchports "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/ports"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

type eventPublisherStub struct {
	events []event.RealtimeEvent
	err    error
}

func (stub *eventPublisherStub) Publish(_ context.Context, realtimeEvent event.RealtimeEvent) error {
	stub.events = append(stub.events, realtimeEvent)
	return stub.err
}

type biddingStoreStub struct {
	session          dispatchdomain.BidSession
	offers           []dispatchdomain.BidOffer
	acceptance       dispatchports.OfferAcceptance
	placeErr         error
	cancelSessionErr error
	cancelOfferErr   error
}

func (stub *biddingStoreStub) CreateSession(_ context.Context, session dispatchdomain.BidSession) (dispatchdomain.BidSession, error) {
	stub.session = session
	stub.session.ID = 55
	return stub.session, nil
}
func (stub *biddingStoreStub) ActiveSessions(context.Context, *int) ([]dispatchdomain.BidSession, error) {
	return nil, nil
}
func (stub *biddingStoreStub) Offers(context.Context, int) ([]dispatchdomain.BidOffer, error) {
	return stub.offers, nil
}
func (stub *biddingStoreStub) PlaceOffer(context.Context, dispatchdomain.BidOffer) (dispatchdomain.BidOffer, error) {
	return dispatchdomain.BidOffer{}, stub.placeErr
}
func (stub *biddingStoreStub) AcceptOffer(
	context.Context,
	int,
	int,
	int,
) (dispatchports.OfferAcceptance, error) {
	return stub.acceptance, nil
}
func (stub *biddingStoreStub) CancelSession(context.Context, int, int) (dispatchdomain.BidSession, error) {
	return dispatchdomain.BidSession{}, stub.cancelSessionErr
}
func (stub *biddingStoreStub) CancelOffer(context.Context, int, int) (dispatchdomain.BidOffer, error) {
	return dispatchdomain.BidOffer{}, stub.cancelOfferErr
}
func (stub *biddingStoreStub) Session(context.Context, int) (dispatchdomain.BidSession, error) {
	return stub.session, nil
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

	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
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
		) (dispatchports.RouteMetrics, error) {
			routeResolved = true
			return dispatchports.RouteMetrics{DistanceKm: 5, DurationMinutes: 15}, nil
		},
		CalculateFare: func(float64, float64) int64 {
			fareCalculated = true
			return 3500
		},
	})

	_, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
	})
	if !errors.Is(err, ridedomain.ErrActiveBooking) {
		t.Fatalf("CreateSession error = %v, want %v", err, ridedomain.ErrActiveBooking)
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
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: store,
		ResolveRoute: func(
			context.Context,
			float64,
			float64,
			float64,
			float64,
			float64,
			float64,
		) (dispatchports.RouteMetrics, error) {
			return dispatchports.RouteMetrics{DistanceKm: 4, DurationMinutes: 12}, nil
		},
		CalculateFare: func(float64, float64) int64 { return 3500 },
		Config:        dispatchapplication.Config{SessionDuration: 90 * time.Second},
		Now:           func() time.Time { return now },
	})

	created, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
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

func TestCreateSessionPublishesToPassengerAndTargetDriver(t *testing.T) {
	store := &biddingStoreStub{}
	publisher := &eventPublisherStub{}
	targetDriverID := 303
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: store,
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (dispatchports.RouteMetrics, error) {
			return dispatchports.RouteMetrics{DistanceKm: 5, DurationMinutes: 15}, nil
		},
		CalculateFare:  func(float64, float64) int64 { return 3500 },
		EventPublisher: publisher,
	})

	created, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:    101,
		TargetDriverID: &targetDriverID,
	})
	if err != nil {
		t.Fatalf("CreateSession() error = %v", err)
	}
	if len(publisher.events) != 1 {
		t.Fatalf("published event count = %d, want 1", len(publisher.events))
	}
	published := publisher.events[0]
	if published.Type != event.RideOfferCreated || published.Scope.PassengerID != "101" ||
		published.Scope.DriverID != "303" || published.Scope.DriverPool {
		t.Fatalf("published event = %+v", published)
	}
	publishedSession, ok := published.Payload["session"].(dispatchdomain.BidSession)
	if !ok || publishedSession.ID != created.ID || publishedSession.PassengerID != created.PassengerID {
		t.Fatalf("published session = %#v, want %+v", published.Payload["session"], created)
	}
}

func TestCreateOpenSessionPublishesToDriverPool(t *testing.T) {
	store := &biddingStoreStub{}
	publisher := &eventPublisherStub{}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: store,
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (dispatchports.RouteMetrics, error) {
			return dispatchports.RouteMetrics{DistanceKm: 5, DurationMinutes: 15}, nil
		},
		CalculateFare:  func(float64, float64) int64 { return 3500 },
		EventPublisher: publisher,
	})

	_, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{PassengerID: 101})
	if err != nil {
		t.Fatalf("CreateSession() error = %v", err)
	}
	if len(publisher.events) != 1 {
		t.Fatalf("published event count = %d, want 1", len(publisher.events))
	}
	published := publisher.events[0]
	if published.Type != event.RideOfferCreated || published.Scope.PassengerID != "101" ||
		published.Scope.DriverID != "" || !published.Scope.DriverPool {
		t.Fatalf("published event = %+v", published)
	}
}

func TestPlaceOfferRecoversAnIdempotentDuplicate(t *testing.T) {
	existing := dispatchdomain.BidOffer{
		ID:                 7,
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 3500,
		Status:             "pending",
	}
	store := &biddingStoreStub{
		offers:   []dispatchdomain.BidOffer{existing},
		placeErr: dispatchdomain.ErrDuplicateBid,
	}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

	created, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
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
		offers: []dispatchdomain.BidOffer{{
			SessionID:          10,
			DriverID:           42,
			ProposedFareAmount: 3500,
			Status:             "pending",
		}},
		placeErr: dispatchdomain.ErrDuplicateBid,
	}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

	_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 4000,
	})
	if !errors.Is(err, dispatchdomain.ErrDuplicateBid) {
		t.Fatalf("PlaceOffer() error = %v, want %v", err, dispatchdomain.ErrDuplicateBid)
	}
}

func TestAcceptOfferPublishesRideMatchedEvent(t *testing.T) {
	store := &biddingStoreStub{}
	publisher := &eventPublisherStub{}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store:          store,
		EventPublisher: publisher,
	})

	_, _, _, err := service.AcceptOffer(context.Background(), 10, 20, 101)
	if err != nil {
		t.Fatalf("AcceptOffer error = %v", err)
	}
	if len(publisher.events) != 1 || publisher.events[0].Type != event.RideMatched {
		t.Fatalf("published events = %#v, want one ride matched event", publisher.events)
	}
}

func TestAcceptOfferPublishesWithdrawnOutstandingOffers(t *testing.T) {
	withdrawnSession := dispatchdomain.BidSession{ID: 33, PassengerID: 202}
	withdrawnOffer := dispatchdomain.BidOffer{
		ID:        44,
		SessionID: withdrawnSession.ID,
		DriverID:  303,
		Status:    "rejected",
	}
	store := &biddingStoreStub{acceptance: dispatchports.OfferAcceptance{
		Session: dispatchdomain.BidSession{ID: 10, PassengerID: 101},
		Offer:   dispatchdomain.BidOffer{ID: 20, SessionID: 10, DriverID: 303, Status: "accepted"},
		Ride:    ridedomain.Ride{ID: 55, PassengerID: 101},
		WithdrawnOffers: []dispatchdomain.BidOfferWithdrawal{
			{Session: withdrawnSession, Offer: withdrawnOffer},
		},
	}}
	publisher := &eventPublisherStub{}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store:          store,
		EventPublisher: publisher,
	})

	if _, _, _, err := service.AcceptOffer(context.Background(), 10, 20, 101); err != nil {
		t.Fatalf("AcceptOffer() error = %v", err)
	}
	if len(publisher.events) != 2 {
		t.Fatalf("published events = %#v, want matched and withdrawn offer events", publisher.events)
	}
	withdrawal := publisher.events[1]
	if withdrawal.Type != event.RideOfferUpdated || withdrawal.Scope.PassengerID != "202" {
		t.Fatalf("withdrawal event = %+v", withdrawal)
	}
	if withdrawal.Payload["offer"] != withdrawnOffer || withdrawal.Payload["reason"] != "driver_unavailable" {
		t.Fatalf("withdrawal payload = %#v", withdrawal.Payload)
	}
}

func TestSessionCopiesOffersAtTheApplicationBoundary(t *testing.T) {
	store := &biddingStoreStub{offers: []dispatchdomain.BidOffer{{ID: 7, Status: "pending"}}}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

	session, err := service.Session(context.Background(), 10)
	if err != nil {
		t.Fatalf("Session() error = %v", err)
	}
	session.Offers[0].Status = "mutated"
	if store.offers[0].Status != "pending" {
		t.Fatalf("store offers were mutated through returned session: %#v", store.offers)
	}
}

func TestCancelSessionRecoversAnAlreadyCancelledSession(t *testing.T) {
	existing := dispatchdomain.BidSession{ID: 10, PassengerID: 101, Status: "cancelled"}
	store := &biddingStoreStub{
		session:          existing,
		cancelSessionErr: errors.New("response lost after cancellation"),
	}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

	recovered, err := service.CancelSession(context.Background(), existing.ID, existing.PassengerID)
	if err != nil {
		t.Fatalf("CancelSession() error = %v", err)
	}
	if recovered.ID != existing.ID ||
		recovered.PassengerID != existing.PassengerID ||
		recovered.Status != existing.Status {
		t.Fatalf("recovered session = %+v, want %+v", recovered, existing)
	}
}

func TestCancelOfferRecoversAnAlreadyRejectedOffer(t *testing.T) {
	existing := dispatchdomain.BidOffer{
		ID:        20,
		SessionID: 10,
		DriverID:  42,
		Status:    "rejected",
	}
	store := &biddingStoreStub{
		offers:         []dispatchdomain.BidOffer{existing},
		cancelOfferErr: errors.New("response lost after cancellation"),
	}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

	recovered, err := service.CancelOffer(context.Background(), existing.SessionID, existing.DriverID)
	if err != nil {
		t.Fatalf("CancelOffer() error = %v", err)
	}
	if recovered != existing {
		t.Fatalf("recovered offer = %+v, want %+v", recovered, existing)
	}
}
