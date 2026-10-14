package application_test

import (
	"context"
	"errors"
	"math"
	"testing"

	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/application"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
	dispatchports "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/ports"
)

type challengerBiddingStoreStub struct {
	session   dispatchdomain.BidSession
	lastOffer dispatchdomain.BidOffer
	placeErr  error
}

func (stub *challengerBiddingStoreStub) Session(context.Context, int) (dispatchdomain.BidSession, error) {
	return stub.session, nil
}
func (stub *challengerBiddingStoreStub) CreateSession(context.Context, dispatchdomain.BidSession) (dispatchdomain.BidSession, error) {
	return dispatchdomain.BidSession{}, nil
}
func (stub *challengerBiddingStoreStub) ActiveSessions(context.Context, *int) ([]dispatchdomain.BidSession, error) {
	return nil, nil
}
func (stub *challengerBiddingStoreStub) Offers(context.Context, int) ([]dispatchdomain.BidOffer, error) {
	return nil, nil
}
func (stub *challengerBiddingStoreStub) PlaceOffer(_ context.Context, offer dispatchdomain.BidOffer) (dispatchdomain.BidOffer, error) {
	stub.lastOffer = offer
	if stub.placeErr != nil {
		return dispatchdomain.BidOffer{}, stub.placeErr
	}
	return offer, nil
}
func (stub *challengerBiddingStoreStub) AcceptOffer(context.Context, int, int, int) (dispatchports.OfferAcceptance, error) {
	return dispatchports.OfferAcceptance{}, nil
}
func (stub *challengerBiddingStoreStub) CancelSession(context.Context, int, int) (dispatchdomain.BidSession, error) {
	return dispatchdomain.BidSession{}, nil
}
func (stub *challengerBiddingStoreStub) CancelOffer(context.Context, int, int) (dispatchdomain.BidOffer, error) {
	return dispatchdomain.BidOffer{}, nil
}

func TestChallengerPlaceOffer_BoundaryAndNegativeOffers(t *testing.T) {
	t.Parallel()

	t.Run("Base fare 200: exact boundary offers", func(t *testing.T) {
		session := dispatchdomain.BidSession{
			ID:                10,
			OfferedFareAmount: 200,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		// Boundary below lower bound (139 < 140)
		_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 139,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 139, got %v", err)
		}

		// Exact lower bound (140)
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 140,
		})
		if err != nil {
			t.Fatalf("expected success for exact min bound 140, got %v", err)
		}
		if store.lastOffer.ProposedFareAmount != 140 {
			t.Fatalf("store received fare %d, want 140", store.lastOffer.ProposedFareAmount)
		}

		// Exact upper bound (400)
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 400,
		})
		if err != nil {
			t.Fatalf("expected success for exact max bound 400, got %v", err)
		}
		if store.lastOffer.ProposedFareAmount != 400 {
			t.Fatalf("store received fare %d, want 400", store.lastOffer.ProposedFareAmount)
		}

		// Boundary above upper bound (401 > 400)
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 401,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 401, got %v", err)
		}
	})

	t.Run("Floor clamp 50: base fare 60", func(t *testing.T) {
		// 0.7 * 60 = 42 < 50 -> minFare clamped to 50
		// maxFare = 2.0 * 60 = 120
		session := dispatchdomain.BidSession{
			ID:                20,
			OfferedFareAmount: 60,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		// 49 rejected
		_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 49,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 49, got %v", err)
		}

		// 50 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 50,
		})
		if err != nil {
			t.Fatalf("expected success for clamped floor min 50, got %v", err)
		}
		if store.lastOffer.ProposedFareAmount != 50 {
			t.Fatalf("store received fare %d, want 50", store.lastOffer.ProposedFareAmount)
		}

		// 120 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 120,
		})
		if err != nil {
			t.Fatalf("expected success for upper bound 120, got %v", err)
		}

		// 121 rejected
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 121,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 121, got %v", err)
		}
	})

	t.Run("Ceiling clamp 5000: base fare 3500", func(t *testing.T) {
		// minFare = 0.7 * 3500 = 2450
		// 2.0 * 3500 = 7000 > 5000 -> maxFare clamped to 5000
		session := dispatchdomain.BidSession{
			ID:                30,
			OfferedFareAmount: 3500,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		// 2449 rejected
		_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 2449,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 2449, got %v", err)
		}

		// 2450 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 2450,
		})
		if err != nil {
			t.Fatalf("expected success for min bound 2450, got %v", err)
		}

		// 5000 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 5000,
		})
		if err != nil {
			t.Fatalf("expected success for clamped ceiling 5000, got %v", err)
		}

		// 5001 rejected
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 5001,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 5001, got %v", err)
		}
	})

	t.Run("Negative offers and zero offer", func(t *testing.T) {
		session := dispatchdomain.BidSession{
			ID:                40,
			OfferedFareAmount: 300,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		// Negative offer: -1
		_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 40, DriverID: 1, ProposedFareAmount: -1,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for -1, got %v", err)
		}

		// Large negative offer
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 40, DriverID: 1, ProposedFareAmount: -10000,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for -10000, got %v", err)
		}

		// math.MinInt64
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 40, DriverID: 1, ProposedFareAmount: math.MinInt64,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for math.MinInt64, got %v", err)
		}

		// Zero offer inherits base fare (300) -> accepted
		offer, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 40, DriverID: 1, ProposedFareAmount: 0,
		})
		if err != nil {
			t.Fatalf("expected zero offer to inherit base fare, got %v", err)
		}
		if offer.ProposedFareAmount != 300 {
			t.Fatalf("expected proposed fare 300, got %d", offer.ProposedFareAmount)
		}
		if store.lastOffer.ProposedFareAmount != 300 {
			t.Fatalf("expected store to receive fare 300, got %d", store.lastOffer.ProposedFareAmount)
		}
	})

	t.Run("Invalid DriverID", func(t *testing.T) {
		session := dispatchdomain.BidSession{
			ID:                50,
			OfferedFareAmount: 200,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		for _, invalidDriverID := range []int{0, -1, -99} {
			_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
				SessionID: 50, DriverID: invalidDriverID, ProposedFareAmount: 200,
			})
			if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
				t.Fatalf("expected ErrInvalidFareOffer for driverID %d, got %v", invalidDriverID, err)
			}
		}
	})
}
