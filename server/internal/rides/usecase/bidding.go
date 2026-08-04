package usecase

import (
	"context"
	"errors"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

var ErrBiddingPersistenceUnavailable = errors.New("bidding persistence is unavailable")

func (service *Service) CreateSession(ctx context.Context, session domain.BidSession) (domain.BidSession, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidSession{}, ErrBiddingPersistenceUnavailable
	}
	if session.RideType == "" {
		session.RideType = "Solo Ride"
	}
	if session.OfferedFareCentavos == 0 {
		session.OfferedFareCentavos = CalculateFare(session.DistanceKm, session.DurationMinutes)
	}
	if session.Status == "" {
		session.Status = "open"
	}
	if session.ExpiresAt.IsZero() {
		session.ExpiresAt = time.Now().Add(5 * time.Minute)
	}
	return repository.CreateSession(ctx, session)
}

func (service *Service) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return nil, ErrBiddingPersistenceUnavailable
	}
	return repository.ActiveSessions(ctx, driverID)
}

func (service *Service) Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return nil, ErrBiddingPersistenceUnavailable
	}
	return repository.Offers(ctx, sessionID)
}

func (service *Service) PlaceOffer(ctx context.Context, offer domain.BidOffer) (domain.BidOffer, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidOffer{}, ErrBiddingPersistenceUnavailable
	}
	if offer.ProposedFareCentavos == 0 {
		session, err := repository.Session(ctx, offer.SessionID)
		if err != nil {
			return domain.BidOffer{}, err
		}
		offer.ProposedFareCentavos = session.OfferedFareCentavos
	}
	if offer.Status == "" {
		offer.Status = "pending"
	}
	return repository.PlaceOffer(ctx, offer)
}

func (service *Service) AcceptOffer(ctx context.Context, sessionID, offerID, driverID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, ErrBiddingPersistenceUnavailable
	}
	return repository.AcceptOffer(ctx, sessionID, offerID, driverID)
}

func (service *Service) CancelSession(ctx context.Context, sessionID int) (domain.BidSession, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidSession{}, ErrBiddingPersistenceUnavailable
	}
	return repository.CancelSession(ctx, sessionID)
}

func (service *Service) CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidOffer{}, ErrBiddingPersistenceUnavailable
	}
	return repository.CancelOffer(ctx, sessionID, driverID)
}

func (service *Service) Session(ctx context.Context, sessionID int) (domain.BidSession, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidSession{}, ErrBiddingPersistenceUnavailable
	}
	session, err := repository.Session(ctx, sessionID)
	if err != nil {
		return domain.BidSession{}, err
	}
	session.Offers, err = repository.Offers(ctx, sessionID)
	return session, err
}
