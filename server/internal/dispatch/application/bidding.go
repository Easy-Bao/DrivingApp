package application

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"slices"
	"strconv"
	"strings"
	"time"

	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/ports"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

var ErrPersistenceUnavailable = errors.New("bidding persistence is unavailable")

type FareCalculator func(distanceKm, durationMinutes float64) int64

type Dependencies struct {
	Store             ports.BiddingStore
	ActiveRideChecker ports.PassengerActiveRideChecker
	ResolveRoute      ports.RouteResolver
	CalculateFare     FareCalculator
	EventPublisher    ports.EventPublisher
	Config            Config
	Now               func() time.Time
}

type Service struct {
	store             ports.BiddingStore
	activeRideChecker ports.PassengerActiveRideChecker
	resolveRoute      ports.RouteResolver
	calculateFare     FareCalculator
	eventPublisher    ports.EventPublisher
	config            Config
	now               func() time.Time
	logger            *slog.Logger
}

func NewService(dependencies Dependencies) *Service {
	activeRideChecker := dependencies.ActiveRideChecker
	if activeRideChecker == nil {
		if checker, ok := dependencies.Store.(ports.PassengerActiveRideChecker); ok {
			activeRideChecker = checker
		}
	}
	now := dependencies.Now
	if now == nil {
		now = time.Now
	}
	return &Service{
		store:             dependencies.Store,
		activeRideChecker: activeRideChecker,
		resolveRoute:      dependencies.ResolveRoute,
		calculateFare:     dependencies.CalculateFare,
		eventPublisher:    dependencies.EventPublisher,
		config:            dependencies.Config,
		now:               now,
		logger:            slog.Default(),
	}
}

func (service *Service) WithLogger(logger *slog.Logger) *Service {
	if service != nil && logger != nil {
		service.logger = logger
	}
	return service
}

// CreateSession opens a passenger bid session using authoritative route
// metrics and pricing.
func (service *Service) CreateSession(ctx context.Context, session dispatchdomain.BidSession) (dispatchdomain.BidSession, error) {
	if service.store == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	if service.resolveRoute == nil || service.calculateFare == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	if service.activeRideChecker != nil {
		hasActive, err := service.activeRideChecker.HasActivePassengerRide(ctx, session.PassengerID)
		if err != nil {
			return dispatchdomain.BidSession{}, fmt.Errorf("check active passenger ride: %w", err)
		}
		if hasActive {
			return dispatchdomain.BidSession{}, ridedomain.ErrActiveBooking
		}
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
		return dispatchdomain.BidSession{}, fmt.Errorf("resolve bidding route: %w", err)
	}
	session.DistanceKm = metrics.DistanceKm
	session.DurationMinutes = metrics.DurationMinutes
	if session.RideType == "" {
		session.RideType = "solo"
	}
	minimumFare := service.calculateFare(metrics.DistanceKm, metrics.DurationMinutes)
	if minimumFare <= 0 {
		return dispatchdomain.BidSession{}, ridedomain.ErrInvalidTrip
	}
	session.OfferedFareAmount = minimumFare
	if session.CustomFareAmount != nil {
		if *session.CustomFareAmount < minimumFare {
			return dispatchdomain.BidSession{}, dispatchdomain.ErrInvalidFareOffer
		}
		session.OfferedFareAmount = *session.CustomFareAmount
	}
	// Session state and expiration are server-owned even for internal callers.
	session.Status = "open"
	session.ExpiresAt = service.now().UTC().Add(service.config.sessionDuration())
	created, err := service.store.CreateSession(ctx, session)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("create bid session: %w", err)
	}
	service.publishSessionEvent(
		ctx,
		event.RideOfferCreated,
		created,
		map[string]any{"session": created},
	)
	return created, nil
}

func (service *Service) ActiveSessions(ctx context.Context, driverID *int) ([]dispatchdomain.BidSession, error) {
	if service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	sessions, err := service.store.ActiveSessions(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("load active bid sessions: %w", err)
	}
	return slices.Clone(sessions), nil
}

func (service *Service) Offers(ctx context.Context, sessionID int) ([]dispatchdomain.BidOffer, error) {
	if service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("load bid offers: %w", err)
	}
	return slices.Clone(offers), nil
}

func (service *Service) PlaceOffer(ctx context.Context, offer dispatchdomain.BidOffer) (dispatchdomain.BidOffer, error) {
	if service.store == nil {
		return dispatchdomain.BidOffer{}, ErrPersistenceUnavailable
	}
	if offer.DriverID <= 0 || offer.ProposedFareAmount < 0 {
		return dispatchdomain.BidOffer{}, dispatchdomain.ErrInvalidFareOffer
	}
	if offer.ProposedFareAmount == 0 {
		session, err := service.store.Session(ctx, offer.SessionID)
		if err != nil {
			return dispatchdomain.BidOffer{}, fmt.Errorf("load bid session for offer: %w", err)
		}
		offer.ProposedFareAmount = session.OfferedFareAmount
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
) (dispatchdomain.BidSession, dispatchdomain.BidOffer, ridedomain.Ride, error) {
	if service.store == nil {
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
		service.publishSessionEvent(
			ctx,
			event.RideOfferUpdated,
			withdrawal.Session,
			map[string]any{
				"offer":  withdrawal.Offer,
				"reason": "driver_unavailable",
			},
		)
	}
	return accepted.Session, accepted.Offer, accepted.Ride, nil
}

func (service *Service) CancelSession(ctx context.Context, sessionID, passengerID int) (dispatchdomain.BidSession, error) {
	if service.store == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	if passengerID <= 0 {
		return dispatchdomain.BidSession{}, dispatchdomain.ErrUnauthorizedSession
	}
	session, err := service.store.CancelSession(ctx, sessionID, passengerID)
	if err != nil {
		recovered, recoveredOK := service.recoverCancelledSession(ctx, sessionID, passengerID)
		if !recoveredOK {
			return dispatchdomain.BidSession{}, fmt.Errorf("cancel bid session: %w", err)
		}
		session = recovered
	}
	service.publishSessionEvent(
		ctx,
		event.RideOfferUpdated,
		session,
		map[string]any{"session": session},
	)
	return session, nil
}

func (service *Service) CancelOffer(ctx context.Context, sessionID, driverID int) (dispatchdomain.BidOffer, error) {
	if service.store == nil {
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

func (service *Service) recoverCancelledSession(
	ctx context.Context,
	sessionID, passengerID int,
) (dispatchdomain.BidSession, bool) {
	recovered, err := service.store.Session(ctx, sessionID)
	if err != nil || recovered.PassengerID != passengerID {
		return dispatchdomain.BidSession{}, false
	}
	return recovered, isBidStatus(recovered.Status, "cancelled")
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

func isBidStatus(value, expected string) bool {
	return strings.EqualFold(strings.TrimSpace(value), expected)
}

func (service *Service) Session(ctx context.Context, sessionID int) (dispatchdomain.BidSession, error) {
	if service.store == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	session, err := service.store.Session(ctx, sessionID)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("load bid session: %w", err)
	}
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("load bid session offers: %w", err)
	}
	session.Offers = slices.Clone(offers)
	return session, nil
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

func (service *Service) publish(
	ctx context.Context,
	eventType event.Type,
	scope event.Scope,
	payload map[string]any,
) {
	if service.eventPublisher == nil {
		return
	}
	if err := service.eventPublisher.Publish(ctx, event.RealtimeEvent{
		Type:    eventType,
		Scope:   scope,
		Payload: payload,
	}); err != nil {
		service.log().WarnContext(ctx, "publish realtime dispatch event failed", "error", err, "event_type", eventType)
	}
}

func positiveIdentifier(value int) string {
	if value <= 0 {
		return ""
	}
	return strconv.Itoa(value)
}

func (service *Service) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}
