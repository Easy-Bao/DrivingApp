// Package bidding owns bid-session and offer use cases.
package bidding

import (
	"context"
	"errors"
	"time"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var ErrPersistenceUnavailable = errors.New("bidding persistence is unavailable")

// FareCalculator calculates the server-authoritative fare.
type FareCalculator func(distanceKm, durationMinutes float64) int64

// RideEventPublisher publishes an event scoped to an authoritative ride.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

// SessionEventPublisher publishes an event scoped to bid-session
// participants.
type SessionEventPublisher func(ctx context.Context, eventType event.Type, session domain.BidSession, payload map[string]any)

// DriverOfferPublisher publishes an offer event scoped to one driver.
type DriverOfferPublisher func(ctx context.Context, offer domain.BidOffer, payload map[string]any)

// Dependencies contains the outbound seams used by bidding use cases.
type Dependencies struct {
	Store              ports.BiddingStore
	ResolveRoute       ports.RouteResolver
	CalculateFare      FareCalculator
	PublishRide        RideEventPublisher
	PublishSession     SessionEventPublisher
	PublishDriverOffer DriverOfferPublisher
}

// Service implements bid-session and offer use cases.
type Service struct {
	store              ports.BiddingStore
	resolveRoute       ports.RouteResolver
	calculateFare      FareCalculator
	publishRide        RideEventPublisher
	publishSession     SessionEventPublisher
	publishDriverOffer DriverOfferPublisher
}

func NewService(dependencies Dependencies) *Service {
	return &Service{
		store:              dependencies.Store,
		resolveRoute:       dependencies.ResolveRoute,
		calculateFare:      dependencies.CalculateFare,
		publishRide:        dependencies.PublishRide,
		publishSession:     dependencies.PublishSession,
		publishDriverOffer: dependencies.PublishDriverOffer,
	}
}

// CreateSession opens a passenger bid session using authoritative route
// metrics and pricing.
func (service *Service) CreateSession(ctx context.Context, session domain.BidSession) (domain.BidSession, error) {
	if service.store == nil {
		return domain.BidSession{}, ErrPersistenceUnavailable
	}
	if service.resolveRoute == nil || service.calculateFare == nil {
		return domain.BidSession{}, ErrPersistenceUnavailable
	}
	metrics, err := service.resolveRoute(
		ctx,
		session.PickupLatitude,
		session.PickupLongitude,
		session.DropoffLatitude,
		session.DropoffLongitude,
		session.DistanceKm,
		session.DurationMinutes,
	)
	if err != nil {
		return domain.BidSession{}, err
	}
	session.DistanceKm = metrics.DistanceKm
	session.DurationMinutes = metrics.DurationMinutes
	if session.RideType == "" {
		session.RideType = "solo"
	}
	minimumFare := service.calculateFare(metrics.DistanceKm, metrics.DurationMinutes)
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
	created, err := service.store.CreateSession(ctx, session)
	if err != nil {
		return domain.BidSession{}, err
	}
	service.publishSessionEvent(ctx, event.RideOfferCreated, created, map[string]any{"session": created})
	return created, nil
}

func (service *Service) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	if service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	return service.store.ActiveSessions(ctx, driverID)
}

func (service *Service) Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error) {
	if service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	return service.store.Offers(ctx, sessionID)
}

func (service *Service) PlaceOffer(ctx context.Context, offer domain.BidOffer) (domain.BidOffer, error) {
	if service.store == nil {
		return domain.BidOffer{}, ErrPersistenceUnavailable
	}
	if offer.DriverID <= 0 || offer.ProposedFareCentavos < 0 {
		return domain.BidOffer{}, domain.ErrInvalidFareOffer
	}
	if offer.ProposedFareCentavos == 0 {
		session, err := service.store.Session(ctx, offer.SessionID)
		if err != nil {
			return domain.BidOffer{}, err
		}
		offer.ProposedFareCentavos = session.OfferedFareCentavos
	}
	if offer.Status == "" {
		offer.Status = "pending"
	}
	created, err := service.store.PlaceOffer(ctx, offer)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if session, sessionErr := service.store.Session(ctx, created.SessionID); sessionErr == nil {
		service.publishSessionEvent(ctx, event.RideOfferUpdated, session, map[string]any{"offer": created})
	} else {
		service.publishDriverOfferEvent(ctx, created, map[string]any{"offer": created})
	}
	return created, nil
}

func (service *Service) AcceptOffer(ctx context.Context, sessionID, offerID, passengerID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	if service.store == nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, ErrPersistenceUnavailable
	}
	if passengerID <= 0 {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	session, offer, ride, err := service.store.AcceptOffer(ctx, sessionID, offerID, passengerID)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, err
	}
	service.publishRideEvent(ctx, event.RideMatched, ride, map[string]any{
		"offer":   offer,
		"ride":    ride,
		"session": session,
	})
	return session, offer, ride, nil
}

func (service *Service) CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error) {
	if service.store == nil {
		return domain.BidSession{}, ErrPersistenceUnavailable
	}
	if passengerID <= 0 {
		return domain.BidSession{}, domain.ErrUnauthorizedSession
	}
	session, err := service.store.CancelSession(ctx, sessionID, passengerID)
	if err != nil {
		return domain.BidSession{}, err
	}
	service.publishSessionEvent(ctx, event.RideOfferUpdated, session, map[string]any{"session": session})
	return session, nil
}

func (service *Service) CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	if service.store == nil {
		return domain.BidOffer{}, ErrPersistenceUnavailable
	}
	offer, err := service.store.CancelOffer(ctx, sessionID, driverID)
	if err != nil {
		return domain.BidOffer{}, err
	}
	if session, sessionErr := service.store.Session(ctx, sessionID); sessionErr == nil {
		service.publishSessionEvent(ctx, event.RideOfferUpdated, session, map[string]any{"offer": offer})
	} else {
		service.publishDriverOfferEvent(ctx, offer, map[string]any{"offer": offer})
	}
	return offer, nil
}

func (service *Service) Session(ctx context.Context, sessionID int) (domain.BidSession, error) {
	if service.store == nil {
		return domain.BidSession{}, ErrPersistenceUnavailable
	}
	session, err := service.store.Session(ctx, sessionID)
	if err != nil {
		return domain.BidSession{}, err
	}
	session.Offers, err = service.store.Offers(ctx, sessionID)
	return session, err
}

func (service *Service) publishRideEvent(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any) {
	if service.publishRide != nil {
		service.publishRide(ctx, eventType, ride, payload)
	}
}

func (service *Service) publishSessionEvent(ctx context.Context, eventType event.Type, session domain.BidSession, payload map[string]any) {
	if service.publishSession != nil {
		service.publishSession(ctx, eventType, session, payload)
	}
}

func (service *Service) publishDriverOfferEvent(ctx context.Context, offer domain.BidOffer, payload map[string]any) {
	if service.publishDriverOffer != nil {
		service.publishDriverOffer(ctx, offer, payload)
	}
}
