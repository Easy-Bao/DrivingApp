package application

import (
	"context"
	"errors"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

var ErrBiddingPersistenceUnavailable = errors.New("bidding persistence is unavailable")

func (service *RideService) CreateSession(ctx context.Context, session domain.BidSession) (domain.BidSession, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidSession{}, ErrBiddingPersistenceUnavailable
	}
	metrics, err := service.authoritativeRoute(ctx, session.PickupLatitude, session.PickupLongitude, session.DropoffLatitude, session.DropoffLongitude, session.DistanceKm, session.DurationMinutes)
	if err != nil {
		return domain.BidSession{}, err
	}
	session.DistanceKm = metrics.DistanceKm
	session.DurationMinutes = metrics.DurationMinutes
	if session.RideType == "" {
		session.RideType = "solo"
	}
	minimumFare := service.CalculateFare(metrics.DistanceKm, metrics.DurationMinutes)
	if minimumFare <= 0 {
		return domain.BidSession{}, domain.ErrInvalidTrip
	}
	session.OfferedFareCentavos = minimumFare
	if session.CustomFareCentavos != nil {
		if *session.CustomFareCentavos < minimumFare {
			return domain.BidSession{}, domain.ErrInvalidFareOffer
		}
		session.OfferedFareCentavos = *session.CustomFareCentavos
	}
	if session.Status == "" {
		session.Status = "open"
	}
	if session.ExpiresAt.IsZero() {
		session.ExpiresAt = time.Now().Add(5 * time.Minute)
	}
	created, err := repository.CreateSession(ctx, session)
	if err != nil {
		return domain.BidSession{}, err
	}
	service.publishSession(ctx, rideCreatedEvent, created, map[string]any{"session": created})
	return created, nil
}

func (service *RideService) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return nil, ErrBiddingPersistenceUnavailable
	}
	return repository.ActiveSessions(ctx, driverID)
}

func (service *RideService) Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return nil, ErrBiddingPersistenceUnavailable
	}
	return repository.Offers(ctx, sessionID)
}

func (service *RideService) PlaceOffer(ctx context.Context, offer domain.BidOffer) (domain.BidOffer, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidOffer{}, ErrBiddingPersistenceUnavailable
	}
	if offer.DriverID <= 0 || offer.ProposedFareCentavos < 0 {
		return domain.BidOffer{}, domain.ErrInvalidFareOffer
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
	created, err := repository.PlaceOffer(ctx, offer)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if session, sessionErr := repository.Session(ctx, created.SessionID); sessionErr == nil {
		service.publishSession(ctx, rideOfferUpdatedEvent, session, map[string]any{"offer": created})
	} else {
		service.publishDriverOffer(ctx, created, map[string]any{"offer": created})
	}
	return created, nil
}

func (service *RideService) AcceptOffer(ctx context.Context, sessionID, offerID, passengerID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, ErrBiddingPersistenceUnavailable
	}
	if passengerID <= 0 {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	session, offer, ride, err := repository.AcceptOffer(ctx, sessionID, offerID, passengerID)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	service.publishRide(ctx, rideMatchedEvent, ride, map[string]any{
		"offer":   offer,
		"ride":    ride,
		"session": session,
	})
	return session, offer, ride, nil
}

func (service *RideService) CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidSession{}, ErrBiddingPersistenceUnavailable
	}
	if passengerID <= 0 {
		return domain.BidSession{}, domain.ErrUnauthorizedSession
	}
	session, err := repository.CancelSession(ctx, sessionID, passengerID)
	if err != nil {
		return domain.BidSession{}, err
	}
	service.publishSession(ctx, rideOfferUpdatedEvent, session, map[string]any{"session": session})
	return session, nil
}

func (service *RideService) CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	repository, ok := service.repository.(domain.BiddingRepository)
	if !ok {
		return domain.BidOffer{}, ErrBiddingPersistenceUnavailable
	}
	offer, err := repository.CancelOffer(ctx, sessionID, driverID)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if session, sessionErr := repository.Session(ctx, sessionID); sessionErr == nil {
		service.publishSession(ctx, rideOfferUpdatedEvent, session, map[string]any{"offer": offer})
	} else {
		service.publishDriverOffer(ctx, offer, map[string]any{"offer": offer})
	}
	return offer, nil
}

func (service *RideService) Session(ctx context.Context, sessionID int) (domain.BidSession, error) {
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
