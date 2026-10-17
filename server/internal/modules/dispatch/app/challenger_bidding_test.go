package app_test

import (
	"context"
	"errors"
	"math"
	"testing"

	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
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
func (stub *challengerBiddingStoreStub) AcceptOffer(context.Context, int, int, int) (dispatchapplication.OfferAcceptance, error) {
	return dispatchapplication.OfferAcceptance{}, nil
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
			OfferedFareAmount: 20000,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		// Boundary below lower bound (13999 < 14000)
		_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 13999,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 13999, got %v", err)
		}

		// Exact lower bound (14000)
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 14000,
		})
		if err != nil {
			t.Fatalf("expected success for exact min bound 14000, got %v", err)
		}
		if store.lastOffer.ProposedFareAmount != 14000 {
			t.Fatalf("store received fare %d, want 14000", store.lastOffer.ProposedFareAmount)
		}

		// Exact upper bound (40000)
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 40000,
		})
		if err != nil {
			t.Fatalf("expected success for exact max bound 40000, got %v", err)
		}
		if store.lastOffer.ProposedFareAmount != 40000 {
			t.Fatalf("store received fare %d, want 40000", store.lastOffer.ProposedFareAmount)
		}

		// Boundary above upper bound (40001 > 40000)
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 10, DriverID: 1, ProposedFareAmount: 40001,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 40001, got %v", err)
		}
	})

	t.Run("Floor clamp 50: base fare 60", func(t *testing.T) {
		// 0.7 * 6000 = 4200 < 5000 -> minFare clamped to 5000
		// maxFare = 2.0 * 6000 = 12000
		session := dispatchdomain.BidSession{
			ID:                20,
			OfferedFareAmount: 6000,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		// 4999 rejected
		_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 4999,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 4999, got %v", err)
		}

		// 5000 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 5000,
		})
		if err != nil {
			t.Fatalf("expected success for clamped floor min 5000, got %v", err)
		}
		if store.lastOffer.ProposedFareAmount != 5000 {
			t.Fatalf("store received fare %d, want 5000", store.lastOffer.ProposedFareAmount)
		}

		// 12000 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 12000,
		})
		if err != nil {
			t.Fatalf("expected success for upper bound 12000, got %v", err)
		}

		// 12001 rejected
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 20, DriverID: 1, ProposedFareAmount: 12001,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 12001, got %v", err)
		}
	})

	t.Run("Ceiling clamp 5000: base fare 3500", func(t *testing.T) {
		// minFare = 0.7 * 350000 = 245000
		// 2.0 * 350000 = 700000 > 500000 -> maxFare clamped to 500000
		session := dispatchdomain.BidSession{
			ID:                30,
			OfferedFareAmount: 350000,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		// 244999 rejected
		_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 244999,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 244999, got %v", err)
		}

		// 245000 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 245000,
		})
		if err != nil {
			t.Fatalf("expected success for min bound 245000, got %v", err)
		}

		// 500000 accepted
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 500000,
		})
		if err != nil {
			t.Fatalf("expected success for clamped ceiling 500000, got %v", err)
		}

		// 500001 rejected
		_, err = service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 30, DriverID: 1, ProposedFareAmount: 500001,
		})
		if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
			t.Fatalf("expected ErrInvalidFareOffer for 500001, got %v", err)
		}
	})

	t.Run("Negative offers and zero offer", func(t *testing.T) {
		session := dispatchdomain.BidSession{
			ID:                40,
			OfferedFareAmount: 30000,
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

		// Zero offer inherits base fare (30000) -> accepted
		offer, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
			SessionID: 40, DriverID: 1, ProposedFareAmount: 0,
		})
		if err != nil {
			t.Fatalf("expected zero offer to inherit base fare, got %v", err)
		}
		if offer.ProposedFareAmount != 30000 {
			t.Fatalf("expected proposed fare 30000, got %d", offer.ProposedFareAmount)
		}
		if store.lastOffer.ProposedFareAmount != 30000 {
			t.Fatalf("expected store to receive fare 30000, got %d", store.lastOffer.ProposedFareAmount)
		}
	})

	t.Run("Invalid DriverID", func(t *testing.T) {
		session := dispatchdomain.BidSession{
			ID:                50,
			OfferedFareAmount: 20000,
		}
		store := &challengerBiddingStoreStub{session: session}
		service := dispatchapplication.NewService(dispatchapplication.Dependencies{Store: store})

		for _, invalidDriverID := range []int{0, -1, -99} {
			_, err := service.PlaceOffer(context.Background(), dispatchdomain.BidOffer{
				SessionID: 50, DriverID: invalidDriverID, ProposedFareAmount: 20000,
			})
			if !errors.Is(err, dispatchdomain.ErrInvalidFareOffer) {
				t.Fatalf("expected ErrInvalidFareOffer for driverID %d, got %v", invalidDriverID, err)
			}
		}
	})
}
