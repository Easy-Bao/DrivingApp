package app

import (
	"context"
	"errors"
	"fmt"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"log/slog"
	"slices"
	"strconv"
	"strings"
	"time"
)

var ErrPersistenceUnavailable = errors.New("bidding persistence is unavailable")

const (
	_dispatchEventPublishTimeout = 2 * time.Second
	_minProposedFareCentavos     = 50_00
	_maxProposedFareCentavos     = 5_000_00
)

type FareCalculator func(distanceKm, durationMinutes float64) int64

type Dependencies struct {
	Store             BiddingStore
	ActiveRideChecker PassengerActiveRideChecker
	ResolveRoute      RouteResolver
	CalculateFare     FareCalculator
	EventPublisher    EventPublisher
	Config            Config
	Now               func() time.Time
}

type Service struct {
	store             BiddingStore
	activeRideChecker PassengerActiveRideChecker
	resolveRoute      RouteResolver
	calculateFare     FareCalculator
	eventPublisher    EventPublisher
	config            Config
	now               func() time.Time
	logger            *slog.Logger
}

func NewService(dependencies Dependencies) *Service {
	now := dependencies.Now
	if now == nil {
		now = time.Now
	}
	return &Service{
		store:             dependencies.Store,
		activeRideChecker: dependencies.ActiveRideChecker,
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
	if service == nil || service.store == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	if service.resolveRoute == nil || service.calculateFare == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	if session.PickupLatitude == session.DropoffLatitude && session.PickupLongitude == session.DropoffLongitude {
		return dispatchdomain.BidSession{}, ridedomain.ErrInvalidTrip
	}
	if session.TargetDriverID != nil && (*session.TargetDriverID <= 0 || *session.TargetDriverID == session.PassengerID) {
		return dispatchdomain.BidSession{}, ridedomain.ErrInvalidTrip
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

	minimumFare := service.calculateFare(metrics.DistanceKm, metrics.DurationMinutes)
	if minimumFare <= 0 {
		return dispatchdomain.BidSession{}, ridedomain.ErrInvalidTrip
	}
	session.OfferedFareAmount = minimumFare
	if session.CustomFareAmount != nil {
		maxCustomFare := max(minimumFare, int64(_maxProposedFareCentavos))
		if *session.CustomFareAmount < minimumFare || *session.CustomFareAmount > maxCustomFare {
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
	if service == nil || service.store == nil {
		return nil, ErrPersistenceUnavailable
	}
	sessions, err := service.store.ActiveSessions(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("load active bid sessions: %w", err)
	}
	return slices.Clone(sessions), nil
}

func (service *Service) DeclineSession(ctx context.Context, sessionID, driverID int) (dispatchdomain.BidSession, error) {
	if service == nil || service.store == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	if driverID <= 0 {
		return dispatchdomain.BidSession{}, dispatchdomain.ErrUnauthorizedSession
	}
	session, err := service.store.DeclineSession(ctx, sessionID, driverID)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("decline ride request: %w", err)
	}
	service.publishSessionEvent(ctx, event.RideOfferUpdated, session, map[string]any{"session": session})
	return session, nil
}

func (service *Service) CancelSession(ctx context.Context, sessionID, passengerID int) (dispatchdomain.BidSession, error) {
	if service == nil || service.store == nil {
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

func (service *Service) recoverCancelledSession(
	ctx context.Context,
	sessionID, passengerID int,
) (dispatchdomain.BidSession, bool) {
	recovered, err := service.store.Session(ctx, sessionID)
	if err != nil || recovered.PassengerID != passengerID {
		return dispatchdomain.BidSession{}, false
	}
	return recovered, isBidStatus(recovered.Status, "cancelled") ||
		isBidStatus(recovered.Status, "expired")
}

func isBidStatus(value, expected string) bool {
	return strings.EqualFold(strings.TrimSpace(value), expected)
}

func (service *Service) Session(ctx context.Context, sessionID int) (dispatchdomain.BidSession, error) {
	if service == nil || service.store == nil {
		return dispatchdomain.BidSession{}, ErrPersistenceUnavailable
	}
	session, err := service.store.Session(ctx, sessionID)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("load bid session: %w", err)
	}
	if isBidStatus(session.Status, "open") && !service.now().UTC().Before(session.ExpiresAt) {
		session.Status = "expired"
	}
	offers, err := service.store.Offers(ctx, sessionID)
	if err != nil {
		return dispatchdomain.BidSession{}, fmt.Errorf("load bid session offers: %w", err)
	}
	session.Offers = slices.Clone(offers)
	return session, nil
}

// SessionForViewer loads a bid session, enforces viewer authorization, and filters
// competing offers when viewed by a driver.
func (service *Service) SessionForViewer(
	ctx context.Context,
	sessionID int,
	actorID int,
	actorRole string,
) (dispatchdomain.BidSession, error) {
	session, err := service.Session(ctx, sessionID)
	if err != nil {
		return dispatchdomain.BidSession{}, err
	}
	if !canViewSession(actorID, actorRole, session) {
		return dispatchdomain.BidSession{}, dispatchdomain.ErrUnauthorizedSession
	}
	return filterSessionForViewer(actorID, session), nil
}

func canViewSession(actorID int, actorRole string, session dispatchdomain.BidSession) bool {
	if actorID <= 0 {
		return false
	}
	if session.PassengerID == actorID {
		return true
	}
	if session.TargetDriverID != nil {
		return *session.TargetDriverID == actorID
	}
	if actorRole != "driver" {
		return false
	}
	if session.AcceptedDriverID != nil && *session.AcceptedDriverID == actorID {
		return true
	}
	status := strings.TrimSpace(session.Status)
	if status == "" || strings.EqualFold(status, "open") {
		return true
	}
	for _, offer := range session.Offers {
		if offer.DriverID == actorID {
			return true
		}
	}
	return false
}

func filterSessionForViewer(actorID int, session dispatchdomain.BidSession) dispatchdomain.BidSession {
	if session.PassengerID == actorID || len(session.Offers) == 0 {
		return session
	}
	filtered := make([]dispatchdomain.BidOffer, 0, 1)
	for _, offer := range session.Offers {
		if offer.DriverID == actorID {
			filtered = append(filtered, offer)
		}
	}
	session.Offers = filtered
	return session
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
	baseCtx := ctx
	if baseCtx == nil {
		baseCtx = context.Background()
	}
	publishCtx, cancel := context.WithTimeout(
		context.WithoutCancel(baseCtx),
		_dispatchEventPublishTimeout,
	)
	defer cancel()
	if err := service.eventPublisher.Publish(publishCtx, event.RealtimeEvent{
		Type:    eventType,
		Scope:   scope,
		Payload: payload,
	}); err != nil {
		service.log().WarnContext(publishCtx, "publish realtime dispatch event failed", "error", err, "event_type", eventType)
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
