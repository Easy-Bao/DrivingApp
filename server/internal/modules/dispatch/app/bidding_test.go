package app_test

import (
	"context"
	"errors"
	"testing"
	"time"

	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
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
	acceptance       dispatchapplication.OfferAcceptance
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
) (dispatchapplication.OfferAcceptance, error) {
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
		) (dispatchapplication.RouteMetrics, error) {
			routeResolved = true
			return dispatchapplication.RouteMetrics{DistanceKm: 5, DurationMinutes: 15}, nil
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
		) (dispatchapplication.RouteMetrics, error) {
			return dispatchapplication.RouteMetrics{DistanceKm: 4, DurationMinutes: 12}, nil
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

func TestCreateSessionUsesAuthoritativeRouteAndCustomFare(t *testing.T) {
	store := &biddingStoreStub{}
	customFare := int64(5000)
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: store,
		ResolveRoute: func(
			_ context.Context,
			_, _, _, _ float64,
			_, _ float64,
		) (dispatchapplication.RouteMetrics, error) {
			return dispatchapplication.RouteMetrics{DistanceKm: 4, DurationMinutes: 20}, nil
		},
		CalculateFare: func(distanceKm, durationMinutes float64) int64 {
			if distanceKm != 4 || durationMinutes != 20 {
				t.Fatalf("fare inputs = (%.2f km, %.2f min), want (4, 20)", distanceKm, durationMinutes)
			}
			return 4000
		},
	})

	created, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
		DistanceKm:       0.01,
		DurationMinutes:  0.01,
		CustomFareAmount: &customFare,
	})
	if err != nil {
		t.Fatalf("CreateSession() error = %v", err)
	}
	if created.DistanceKm != 4 || created.DurationMinutes != 20 || created.OfferedFareAmount != customFare {
		t.Fatalf("created session = %+v, want authoritative metrics and custom fare", created)
	}
}

func TestCreateSessionRejectsCustomFareBelowMinimum(t *testing.T) {
	store := &biddingStoreStub{}
	customFare := int64(3999)
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: store,
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (dispatchapplication.RouteMetrics, error) {
			return dispatchapplication.RouteMetrics{DistanceKm: 4, DurationMinutes: 20}, nil
		},
		CalculateFare: func(float64, float64) int64 { return 4000 },
	})

	_, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
		CustomFareAmount: &customFare,
	})
	if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
		t.Fatalf("CreateSession() error = %v, want %v", err, dispatchdomain.ErrInvalidFareOffer)
	}
	if store.session.ID != 0 {
		t.Fatal("invalid custom fare must not persist a session")
	}
}

func TestCreateSessionPreservesRouteResolutionError(t *testing.T) {
	store := &biddingStoreStub{}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: store,
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (dispatchapplication.RouteMetrics, error) {
			return dispatchapplication.RouteMetrics{}, context.Canceled
		},
		CalculateFare: func(float64, float64) int64 { return 4000 },
	})

	_, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
	})
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("CreateSession() error = %v, want context cancellation", err)
	}
	if store.session.ID != 0 {
		t.Fatal("session must not be persisted when route resolution fails")
	}
}

func TestCreateSessionPublishesToPassengerAndTargetDriver(t *testing.T) {
	store := &biddingStoreStub{}
	publisher := &eventPublisherStub{}
	targetDriverID := 303
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: store,
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (dispatchapplication.RouteMetrics, error) {
			return dispatchapplication.RouteMetrics{DistanceKm: 5, DurationMinutes: 15}, nil
		},
		CalculateFare:  func(float64, float64) int64 { return 3500 },
		EventPublisher: publisher,
	})

	created, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
		TargetDriverID:   &targetDriverID,
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
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (dispatchapplication.RouteMetrics, error) {
			return dispatchapplication.RouteMetrics{DistanceKm: 5, DurationMinutes: 15}, nil
		},
		CalculateFare:  func(float64, float64) int64 { return 3500 },
		EventPublisher: publisher,
	})

	_, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.6,
		DropoffLongitude: 121.1,
	})
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
		ProposedFareAmount: 5500,
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
			ProposedFareAmount: 5500,
			Status:             "pending",
		}},
		placeErr: dispatchdomain.ErrDuplicateBid,
	}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

	_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 6000,
	})
	if !errors.Is(err, dispatchdomain.ErrDuplicateBid) {
		t.Fatalf("PlaceOffer() error = %v, want %v", err, dispatchdomain.ErrDuplicateBid)
	}
}

func TestPlaceOfferEnforcesFareBounds(t *testing.T) {
	// Base fare 20000 (₱200.00): lower bound = max(5000, 0.70*20000) = 14000, upper bound = min(500000, 2.0*20000) = 40000
	session := dispatchdomain.BidSession{
		ID:                10,
		OfferedFareAmount: 20000,
	}
	store := &biddingStoreStub{session: session}
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

	// Offer below lower bound (10000 < 14000)
	_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 10000,
	})
	if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
		t.Fatalf("expected ErrInvalidFareOffer for low bid, got %v", err)
	}

	// Offer above upper bound (45000 > 40000)
	_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 45000,
	})
	if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
		t.Fatalf("expected ErrInvalidFareOffer for high bid, got %v", err)
	}

	// Offer within bounds (25000)
	_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 25000,
	})
	if err != nil {
		t.Fatalf("expected success for valid bid, got %v", err)
	}

	// Absolute cap test: base fare 300000: upper bound = min(500000, 2.0*300000) = 500000
	store.session.OfferedFareAmount = 300000
	_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
		SessionID:          10,
		DriverID:           42,
		ProposedFareAmount: 550000,
	})
	if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
		t.Fatalf("expected ErrInvalidFareOffer for exceeding absolute 500000 cap, got %v", err)
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

func TestAcceptOfferPublishesRejectedCompetingOfferToItsDriver(t *testing.T) {
	rejectedOffer := dispatchdomain.BidOffer{
		ID:        21,
		SessionID: 10,
		DriverID:  404,
		Status:    "rejected",
	}
	store := &biddingStoreStub{acceptance: dispatchapplication.OfferAcceptance{
		Session:        dispatchdomain.BidSession{ID: 10, PassengerID: 101},
		Offer:          dispatchdomain.BidOffer{ID: 20, SessionID: 10, DriverID: 303, Status: "accepted"},
		Ride:           ridedomain.Ride{ID: 55, PassengerID: 101},
		RejectedOffers: []dispatchdomain.BidOffer{rejectedOffer},
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
		t.Fatalf("published events = %#v, want match and one competing-offer update", publisher.events)
	}
	updated := publisher.events[1]
	if updated.Type != event.RideOfferUpdated || updated.Scope.DriverID != "404" ||
		updated.Scope.PassengerID != "" || updated.Scope.DriverPool {
		t.Fatalf("competing-offer event scope = %+v, want only driver 404", updated)
	}
	wantPayload := map[string]any{
		"offer_id":   rejectedOffer.ID,
		"session_id": rejectedOffer.SessionID,
		"reason":     "another_driver_selected",
	}
	for key, want := range wantPayload {
		if got := updated.Payload[key]; got != want {
			t.Errorf("competing-offer payload[%q] = %#v, want %#v", key, got, want)
		}
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
	store := &biddingStoreStub{acceptance: dispatchapplication.OfferAcceptance{
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

func TestCreateSessionRejectsIdenticalPickupAndDropoff(t *testing.T) {
	service := dispatchapplication.NewService(dispatchapplication.Dependencies{
		Store: &biddingStoreStub{},
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (dispatchapplication.RouteMetrics, error) {
			return dispatchapplication.RouteMetrics{DistanceKm: 0, DurationMinutes: 0}, nil
		},
		CalculateFare: func(float64, float64) int64 { return 2500 },
	})

	_, err := service.CreateSession(context.Background(), dispatchdomain.BidSession{
		PassengerID:      101,
		PickupLatitude:   14.5,
		PickupLongitude:  121.0,
		DropoffLatitude:  14.5,
		DropoffLongitude: 121.0,
	})
	if !errors.Is(err, ridedomain.ErrInvalidTrip) {
		t.Fatalf("CreateSession error = %v, want %v", err, ridedomain.ErrInvalidTrip)
	}
}
