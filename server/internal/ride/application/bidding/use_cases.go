// Package bidding owns bid-session and offer use cases.
package bidding

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var ErrPersistenceUnavailable = errors.New("bidding persistence is unavailable")

// FareCalculator keeps pricing policy injectable at the application boundary.
type FareCalculator func(distanceKm, durationMinutes float64) int64

// RideEventPublisher routes a post-persistence event for an authoritative ride.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

// SessionEventPublisher routes transient updates to bid-session participants.
type SessionEventPublisher func(
	ctx context.Context,
	eventType event.Type,
	session domain.BidSession,
	payload map[string]any,
)

// DriverOfferPublisher keeps offer delivery targeted to its driver.
type DriverOfferPublisher func(ctx context.Context, offer domain.BidOffer, payload map[string]any)

// Dependencies collects the policies and ports that make bidding independent
// of concrete adapters.
type Dependencies struct {
	Store              ports.BiddingStore
	ResolveRoute       ports.RouteResolver
	CalculateFare      FareCalculator
	PublishRide        RideEventPublisher
	PublishSession     SessionEventPublisher
	PublishDriverOffer DriverOfferPublisher
}

// Service keeps bid-session decisions behind the ride application's ports.
type Service struct {
	store              ports.BiddingStore
	resolveRoute       ports.RouteResolver
	calculateFare      FareCalculator
	publishRide        RideEventPublisher
	publishSession     SessionEventPublisher
	publishDriverOffer DriverOfferPublisher
	logger             *slog.Logger
}

func NewService(dependencies Dependencies) *Service {
	return &Service{
		store:              dependencies.Store,
		resolveRoute:       dependencies.ResolveRoute,
		calculateFare:      dependencies.CalculateFare,
		publishRide:        dependencies.PublishRide,
		publishSession:     dependencies.PublishSession,
		publishDriverOffer: dependencies.PublishDriverOffer,
		logger:             slog.Default(),
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
		return domain.BidSession{}, fmt.Errorf("resolve bidding route: %w", err)
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
		return domain.BidSession{}, fmt.Errorf("create bid session: %w", err)
	}
	service.publishSessionEvent(
		ctx,
		event.RideOfferCreated,
		created,
		map[string]any{"session": created},
	)
	return created, nil
}

func (service *Service) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	if service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	sessions, err := service.store.ActiveSessions(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("load active bid sessions: %w", err)
	}
	return sessions, nil
}

func (service *Service) Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error) {
	if service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("load bid offers: %w", err)
	}
	return offers, nil
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
			return domain.BidOffer{}, fmt.Errorf("load bid session for offer: %w", err)
		}
		offer.ProposedFareCentavos = session.OfferedFareCentavos
	}
	if offer.Status == "" {
		offer.Status = "pending"
	}
	created, err := service.store.PlaceOffer(ctx, offer)
	if err != nil {
		return domain.BidOffer{}, fmt.Errorf("place bid offer: %w", err)
	}
	session, sessionErr := service.store.Session(ctx, created.SessionID)
	if sessionErr == nil {
		service.publishSessionEvent(
			ctx,
			event.RideOfferUpdated,
			session,
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
) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	if service.store == nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, ErrPersistenceUnavailable
	}
	if passengerID <= 0 {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, domain.ErrUnauthorizedSession
	}
	session, offer, ride, err := service.store.AcceptOffer(
		ctx,
		sessionID,
		offerID,
		passengerID,
	)
	if err != nil {
		return domain.BidSession{}, domain.BidOffer{}, domain.Ride{}, fmt.Errorf("accept bid offer: %w", err)
	}
	service.publishRideEvent(
		ctx,
		event.RideMatched,
		ride,
		map[string]any{
			"offer":   offer,
			"ride":    ride,
			"session": session,
		},
	)
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
		return domain.BidSession{}, fmt.Errorf("cancel bid session: %w", err)
	}
	service.publishSessionEvent(
		ctx,
		event.RideOfferUpdated,
		session,
		map[string]any{"session": session},
	)
	return session, nil
}

func (service *Service) CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	if service.store == nil {
		return domain.BidOffer{}, ErrPersistenceUnavailable
	}
	offer, err := service.store.CancelOffer(ctx, sessionID, driverID)
	if err != nil {
		return domain.BidOffer{}, fmt.Errorf("cancel bid offer: %w", err)
	}
	session, sessionErr := service.store.Session(ctx, sessionID)
	if sessionErr == nil {
		service.publishSessionEvent(
			ctx,
			event.RideOfferUpdated,
			session,
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

func (service *Service) Session(ctx context.Context, sessionID int) (domain.BidSession, error) {
	if service.store == nil {
		return domain.BidSession{}, ErrPersistenceUnavailable
	}
	session, err := service.store.Session(ctx, sessionID)
	if err != nil {
		return domain.BidSession{}, fmt.Errorf("load bid session: %w", err)
	}
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return domain.BidSession{}, fmt.Errorf("load bid session offers: %w", err)
	}
	session.Offers = offers
	return session, nil
}

func (service *Service) publishRideEvent(
	ctx context.Context,
	eventType event.Type,
	ride domain.Ride,
	payload map[string]any,
) {
	if service.publishRide != nil {
		service.publishRide(
			ctx,
			eventType,
			ride,
			payload,
		)
	}
}

func (service *Service) publishSessionEvent(
	ctx context.Context,
	eventType event.Type,
	session domain.BidSession,
	payload map[string]any,
) {
	if service.publishSession != nil {
		service.publishSession(
			ctx,
			eventType,
			session,
			payload,
		)
	}
}

func (service *Service) publishDriverOfferEvent(ctx context.Context, offer domain.BidOffer, payload map[string]any) {
	if service.publishDriverOffer != nil {
		service.publishDriverOffer(ctx, offer, payload)
	}
}

func (service *Service) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}
