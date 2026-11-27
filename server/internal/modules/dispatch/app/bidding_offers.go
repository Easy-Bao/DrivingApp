package app

import (
	"context"
	"errors"
	"fmt"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"math"
	"slices"
)

func (service *Service) Offers(ctx context.Context, sessionID int) ([]dispatchdomain.BidOffer, error) {
	if service == nil || service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("load bid offers: %w", err)
	}
	return slices.Clone(offers), nil
}

func (service *Service) PlaceOffer(ctx context.Context, offer dispatchdomain.BidOffer) (dispatchdomain.BidOffer, error) {
	if service == nil || service.store == nil {
		return dispatchdomain.BidOffer{}, ErrPersistenceUnavailable
	}
	if offer.DriverID <= 0 || offer.ProposedFareAmount < 0 {
		return dispatchdomain.BidOffer{}, dispatchdomain.ErrInvalidFareOffer
	}
	session, err := service.store.Session(ctx, offer.SessionID)
	if err != nil {
		return dispatchdomain.BidOffer{}, fmt.Errorf("load bid session for offer: %w", err)
	}
	if offer.ProposedFareAmount == 0 {
		offer.ProposedFareAmount = session.OfferedFareAmount
	}
	if !withinOfferFareBounds(session.OfferedFareAmount, offer.ProposedFareAmount) {
		return dispatchdomain.BidOffer{}, dispatchdomain.ErrInvalidFareOffer
	}
	if offer.Status == "" {
		offer.Status = "pending"
	}
	created, err := service.store.PlaceOffer(ctx, offer)
	if err != nil {
		if errors.Is(err, dispatchdomain.ErrDuplicateBid) {
			existingOffers, lookupErr := service.store.Offers(ctx, offer.SessionID)
			if lookupErr != nil {
				return dispatchdomain.BidOffer{}, fmt.Errorf("recover duplicate bid offer: %w", lookupErr)
			}
			for _, existing := range existingOffers {
				if existing.SessionID != offer.SessionID ||
					existing.DriverID != offer.DriverID ||
					existing.ProposedFareAmount != offer.ProposedFareAmount {
					continue
				}
				if existing.Status == "pending" || existing.Status == "accepted" {
					return existing, nil
				}
			}
		}
		return dispatchdomain.BidOffer{}, fmt.Errorf("place bid offer: %w", err)
	}
	session, sessionErr := service.store.Session(ctx, created.SessionID)
	if sessionErr == nil {
		service.publishOfferEvent(
			ctx,
			session,
			created,
			map[string]any{"offer": created},
		)
	} else {
		service.log().DebugContext(
			ctx,
			"load bid session after offer placement failed; using driver notification",
			"error",
			sessionErr,
		)
		service.publishDriverOfferEvent(ctx, created, map[string]any{"offer": created})
	}
	return created, nil
}

func (service *Service) AcceptOffer(
	ctx context.Context,
	sessionID int,
	offerID int,
	passengerID int,
) (dispatchdomain.BidSession, dispatchdomain.BidOffer, ridedomain.Ride, error) {
	if service == nil || service.store == nil {
		return dispatchdomain.BidSession{}, dispatchdomain.BidOffer{}, ridedomain.Ride{}, ErrPersistenceUnavailable
	}
	if passengerID <= 0 {
		return dispatchdomain.BidSession{}, dispatchdomain.BidOffer{}, ridedomain.Ride{}, dispatchdomain.ErrUnauthorizedSession
	}
	accepted, err := service.store.AcceptOffer(
		ctx,
		sessionID,
		offerID,
		passengerID,
	)
	if err != nil {
		return dispatchdomain.BidSession{}, dispatchdomain.BidOffer{}, ridedomain.Ride{}, fmt.Errorf("accept bid offer: %w", err)
	}
	if !accepted.Replayed {
		service.publishRideEvent(
			ctx,
			event.RideMatched,
			accepted.Ride,
			map[string]any{
				"offer":   accepted.Offer,
				"ride":    accepted.Ride,
				"session": accepted.Session,
			},
		)
		for _, rejectedOffer := range accepted.RejectedOffers {
			service.publishDriverOfferEvent(
				ctx,
				rejectedOffer,
				map[string]any{
					"offer_id":   rejectedOffer.ID,
					"session_id": rejectedOffer.SessionID,
					"reason":     "another_driver_selected",
				},
			)
		}
		for _, withdrawal := range accepted.WithdrawnOffers {
			service.publishOfferEvent(
				ctx,
				withdrawal.Session,
				withdrawal.Offer,
				map[string]any{
					"offer":  withdrawal.Offer,
					"reason": "driver_unavailable",
				},
			)
		}
	}
	return accepted.Session, accepted.Offer, accepted.Ride, nil
}

func (service *Service) CancelOffer(ctx context.Context, sessionID, driverID int) (dispatchdomain.BidOffer, error) {
	if service == nil || service.store == nil {
		return dispatchdomain.BidOffer{}, ErrPersistenceUnavailable
	}
	offer, err := service.store.CancelOffer(ctx, sessionID, driverID)
	if err != nil {
		recovered, recoveredOK := service.recoverRejectedOffer(ctx, sessionID, driverID)
		if !recoveredOK {
			return dispatchdomain.BidOffer{}, fmt.Errorf("cancel bid offer: %w", err)
		}
		offer = recovered
	}
	session, sessionErr := service.store.Session(ctx, sessionID)
	if sessionErr == nil {
		service.publishOfferEvent(
			ctx,
			session,
			offer,
			map[string]any{"offer": offer},
		)
	} else {
		service.log().DebugContext(
			ctx,
			"load bid session after offer cancellation failed; using driver notification",
			"error",
			sessionErr,
		)
		service.publishDriverOfferEvent(ctx, offer, map[string]any{"offer": offer})
	}
	return offer, nil
}

func (service *Service) recoverRejectedOffer(
	ctx context.Context,
	sessionID, driverID int,
) (dispatchdomain.BidOffer, bool) {
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return dispatchdomain.BidOffer{}, false
	}
	for _, offer := range offers {
		if offer.SessionID == sessionID &&
			offer.DriverID == driverID &&
			isBidStatus(offer.Status, "rejected") {
			return offer, true
		}
	}
	return dispatchdomain.BidOffer{}, false
}

func (service *Service) OffersForViewer(
	ctx context.Context,
	sessionID int,
	actorID int,
) ([]dispatchdomain.BidOffer, error) {
	if service == nil || service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	session, err := service.store.Session(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("load bid session: %w", err)
	}
	if actorID <= 0 || session.PassengerID != actorID {
		return nil, dispatchdomain.ErrUnauthorizedSession
	}
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("load bid offers: %w", err)
	}
	return slices.Clone(offers), nil
}

func withinOfferFareBounds(offeredFareAmount, proposedFareAmount int64) bool {
	if offeredFareAmount <= 0 {
		return proposedFareAmount >= _minProposedFareCentavos && proposedFareAmount <= _maxProposedFareCentavos
	}
	baseFare := float64(offeredFareAmount)
	minFare := min(offeredFareAmount, max(int64(_minProposedFareCentavos), int64(math.Round(0.70*baseFare))))
	maxFare := max(min(int64(_maxProposedFareCentavos), int64(math.Round(2.0*baseFare))), minFare, offeredFareAmount)
	return proposedFareAmount >= minFare && proposedFareAmount <= maxFare
}

func (service *Service) publishOfferEvent(
	ctx context.Context,
	session dispatchdomain.BidSession,
	offer dispatchdomain.BidOffer,
	payload map[string]any,
) {
	service.publish(
		ctx,
		event.RideOfferUpdated,
		event.Scope{
			PassengerID: positiveIdentifier(session.PassengerID),
			DriverID:    positiveIdentifier(offer.DriverID),
		},
		payload,
	)
}

func (service *Service) publishRideEvent(
	ctx context.Context,
	eventType event.Type,
	ride ridedomain.Ride,
	payload map[string]any,
) {
	scope := event.Scope{
		RideID:      positiveIdentifier(ride.ID),
		PassengerID: positiveIdentifier(ride.PassengerID),
	}
	if ride.DriverID != nil {
		scope.DriverID = positiveIdentifier(*ride.DriverID)
	}
	service.publish(ctx, eventType, scope, payload)
}

func (service *Service) publishSessionEvent(
	ctx context.Context,
	eventType event.Type,
	session dispatchdomain.BidSession,
	payload map[string]any,
) {
	scope := event.Scope{
		PassengerID: positiveIdentifier(session.PassengerID),
		DriverPool:  session.TargetDriverID == nil && session.AcceptedDriverID == nil,
	}
	if session.TargetDriverID != nil {
		scope.DriverID = positiveIdentifier(*session.TargetDriverID)
	}
	if session.AcceptedDriverID != nil {
		scope.DriverID = positiveIdentifier(*session.AcceptedDriverID)
	}
	service.publish(ctx, eventType, scope, payload)
}

func (service *Service) publishDriverOfferEvent(ctx context.Context, offer dispatchdomain.BidOffer, payload map[string]any) {
	service.publish(
		ctx,
		event.RideOfferUpdated,
		event.Scope{DriverID: positiveIdentifier(offer.DriverID)},
		payload,
	)
}
