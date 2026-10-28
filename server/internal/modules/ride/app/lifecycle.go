package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

var ErrPersistenceUnavailable = errors.New("ride lifecycle persistence is unavailable")

type LifecycleDependencies struct {
	Store          RideLifecycleStore
	DriverLocation DriverLocationReader
	PublishRide    RideEventPublisher
	Config         LifecycleConfig
}

type LifecycleService struct {
	store          RideLifecycleStore
	driverLocation DriverLocationReader
	publishRide    RideEventPublisher
	config         LifecycleConfig
}

func NewLifecycleService(dependencies LifecycleDependencies) *LifecycleService {
	return &LifecycleService{
		store:          dependencies.Store,
		driverLocation: dependencies.DriverLocation,
		publishRide:    dependencies.PublishRide,
		config:         dependencies.Config,
	}
}

func (service *LifecycleService) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for acceptance: %w", err)
	}
	currentStatus, currentStatusOK := domain.NormalizeRideStatus(current.Status)
	if current.DriverID != nil &&
		*current.DriverID == driverID &&
		currentStatusOK &&
		domain.IsActive(current.Status) &&
		currentStatus != domain.RideRequested {
		return current, nil
	}
	ride, err := service.store.AcceptRide(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("accept ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideMatched,
		ride,
		map[string]any{"ride": ride},
	)
	return ride, nil
}

// UpdateStatus validates the current aggregate state and persists the next
// participant-authorized status.
func (service *LifecycleService) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
	return service.transition(ctx, rideID, actorID, next, domain.RideTransition{
		EventType: domain.RideEventStatusChanged,
	})
}

func (service *LifecycleService) StartTrip(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, location, err := service.loadRideWithDriverLocation(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for trip start: %w", err)
	}
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	status, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status == domain.RideInTransit {
		return current, nil
	}
	if status != domain.RideArrived {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	driverLat, driverLng, err := location()
	if err != nil {
		return domain.Ride{}, err
	}
	if err := domain.ValidateArrivalLocation(
		current.PickupLatitude,
		current.PickupLongitude,
		driverLat,
		driverLng,
		service.config.arrivalRadiusMeters(),
	); err != nil {
		return domain.Ride{}, err
	}
	if current.ArrivedAt != nil {
		arrivedAt, parseErr := time.Parse(time.RFC3339, *current.ArrivedAt)
		if parseErr != nil {
			arrivedAt, parseErr = time.Parse(time.RFC3339Nano, *current.ArrivedAt)
		}
		if parseErr == nil && time.Since(arrivedAt) < 3*time.Second {
			return domain.Ride{}, domain.ErrInvalidStatusTransition
		}
	}
	updated, err := service.store.StartTrip(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("start ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(domain.RideArrived),
			"ride":            updated,
		},
	)
	return updated, nil
}

func (service *LifecycleService) CompleteTrip(
	ctx context.Context,
	rideID, driverID int,
	_, _ float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for trip completion: %w", err)
	}
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	status, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status == domain.RideCompleted {
		return current, nil
	}
	if status != domain.RideInTransit {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	updated, err := service.store.CompleteTrip(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("complete ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(domain.RideInTransit),
			"ride":            updated,
		},
	)
	return updated, nil
}

func (service *LifecycleService) MarkArrived(
	ctx context.Context,
	rideID, driverID int,
	_, _ float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, location, err := service.loadRideWithDriverLocation(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for arrival: %w", err)
	}
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	normalizedStatus, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if normalizedStatus == domain.RideArrived {
		return current, nil
	}
	if normalizedStatus != domain.RideAssigned && normalizedStatus != domain.RideAccepted {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	driverLatitude, driverLongitude, err := location()
	if err != nil {
		return domain.Ride{}, err
	}
	if err := domain.ValidateArrivalLocation(
		current.PickupLatitude,
		current.PickupLongitude,
		driverLatitude,
		driverLongitude,
		service.config.arrivalRadiusMeters(),
	); err != nil {
		return domain.Ride{}, err
	}
	updated, err := service.store.MarkArrived(
		ctx,
		rideID,
		driverID,
		string(normalizedStatus),
		service.config.passengerWaitDuration(),
	)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("mark ride arrived: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(normalizedStatus),
			"ride":            updated,
		},
	)
	return updated, nil
}

type driverLocationResult struct {
	latitude, longitude float64
	err                 error
}

// loadRideWithDriverLocation reads the ride and the authoritative driver
// location concurrently so location-gated commands pay one round trip of
// latency instead of two. The returned function blocks until the location
// read finishes; callers still evaluate ride ownership and status first so
// error precedence is unchanged. The location read is cancelled and drained
// when the ride cannot be loaded.
func (service *LifecycleService) loadRideWithDriverLocation(
	ctx context.Context,
	rideID, driverID int,
) (domain.Ride, func() (float64, float64, error), error) {
	locationCtx, cancel := context.WithCancel(ctx)
	results := make(chan driverLocationResult, 1)
	go func() {
		defer cancel()
		latitude, longitude, err := service.authoritativeDriverLocation(locationCtx, driverID)
		results <- driverLocationResult{latitude: latitude, longitude: longitude, err: err}
	}()
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		cancel()
		<-results
		return domain.Ride{}, nil, err
	}
	var (
		once   bool
		result driverLocationResult
	)
	return current, func() (float64, float64, error) {
		if !once {
			once = true
			result = <-results
		}
		return result.latitude, result.longitude, result.err
	}, nil
}

func (service *LifecycleService) authoritativeDriverLocation(
	ctx context.Context,
	driverID int,
) (float64, float64, error) {
	if service.driverLocation == nil {
		return 0, 0, domain.ErrDriverLocationUnavailable
	}
	point, err := service.driverLocation.ReadDriverLocation(ctx, driverID)
	if err != nil {
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			return 0, 0, err
		}
		return 0, 0, fmt.Errorf("read authoritative driver location: %w: %v", domain.ErrDriverLocationUnavailable, err)
	}
	if point.ObservedAt.IsZero() {
		return 0, 0, domain.ErrDriverLocationUnavailable
	}
	observedAge := time.Since(point.ObservedAt)
	if observedAge < 0 || observedAge > service.config.driverLocationMaxAge() {
		return 0, 0, domain.ErrDriverLocationStale
	}
	return point.Latitude, point.Longitude, nil
}

func (service *LifecycleService) MarkPassengerNoShow(
	ctx context.Context,
	rideID, driverID int,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for passenger no-show: %w", err)
	}
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	status, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status == domain.RideCancelled {
		if current.CancelledBy != nil &&
			*current.CancelledBy == driverID &&
			domain.NormalizeCancellationReason(current.CancellationReason) ==
				domain.CancellationReasonPassengerNoShow &&
			current.CancellationResponsibility ==
				string(domain.CancellationResponsibilityPassengerFault) {
			return current, nil
		}
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status != domain.RideArrived {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if current.WaitingUntil == nil {
		return domain.Ride{}, domain.ErrPassengerNoShowNotReady
	}
	waitingUntil, parseErr := time.Parse(time.RFC3339, *current.WaitingUntil)
	if parseErr != nil {
		waitingUntil, parseErr = time.Parse(time.RFC3339Nano, *current.WaitingUntil)
	}
	if parseErr != nil || time.Now().UTC().Before(waitingUntil.Add(-5*time.Second)) {
		return domain.Ride{}, domain.ErrPassengerNoShowNotReady
	}
	updated, err := service.store.MarkPassengerNoShow(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("mark passenger no-show: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(domain.RideArrived),
			"reason":          string(domain.CancellationReasonPassengerNoShow),
			"responsibility":  string(domain.CancellationResponsibilityPassengerFault),
			"ride":            updated,
		},
	)
	return updated, nil
}

// Cancel applies the ordinary cancellation policy and records the reason and
// server-derived responsibility with the same transaction as the status
// change. Emergency termination uses its own safety command.
func (service *LifecycleService) Cancel(ctx context.Context, request domain.CancellationRequest) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, request.RideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for cancellation: %w", err)
	}
	actor := domain.CancellationActor("")
	switch {
	case current.PassengerID == request.ActorID:
		actor = domain.CancellationActorPassenger
	case current.DriverID != nil && *current.DriverID == request.ActorID:
		actor = domain.CancellationActorDriver
	default:
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	normalizedReason := domain.NormalizeCancellationReason(string(request.Reason))
	if normalizedStatus, ok := domain.NormalizeRideStatus(current.Status); ok && normalizedStatus == domain.RideCancelled {
		if current.CancelledBy != nil &&
			*current.CancelledBy == request.ActorID &&
			domain.NormalizeCancellationReason(current.CancellationReason) == normalizedReason &&
			strings.TrimSpace(current.CancellationDetails) == strings.TrimSpace(request.Details) {
			return current, nil
		}
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if normalizedReason == domain.CancellationReasonPassengerNoShow {
		return domain.Ride{}, domain.ErrNoShowCommand
	}
	responsibility, details, err := domain.ValidateCancellation(
		actor,
		current.Status,
		request.Reason,
		request.Details,
	)
	if err != nil {
		return domain.Ride{}, err
	}
	return service.transition(ctx, request.RideID, request.ActorID, string(domain.RideCancelled), domain.RideTransition{
		EventType:      domain.RideEventCancelled,
		Reason:         normalizedReason,
		Responsibility: responsibility,
		Details:        details,
	})
}

// EmergencyStop ends an active ride through a dedicated safety command. It
// records the safety attribution and reason in the same atomic status update,
// rather than routing an emergency through ordinary cancellation policy.
func (service *LifecycleService) EmergencyStop(
	ctx context.Context,
	request domain.EmergencyStopRequest,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, request.RideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for emergency stop: %w", err)
	}
	isPassenger := current.PassengerID == request.ActorID
	isDriver := current.DriverID != nil && *current.DriverID == request.ActorID
	if !isPassenger && !isDriver {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}

	reason := domain.NormalizeEmergencyStopReason(string(request.Reason))
	if current.Status == string(domain.RideCancelled) &&
		current.CancelledBy != nil &&
		*current.CancelledBy == request.ActorID &&
		domain.NormalizeEmergencyStopReason(current.CancellationReason) == reason {
		return current, nil
	}
	normalizedReason, details, err := domain.ValidateEmergencyStop(
		current.Status,
		request.Reason,
		request.Details,
	)
	if err != nil {
		return domain.Ride{}, err
	}

	updated, err := service.store.UpdateStatus(
		ctx,
		request.RideID,
		request.ActorID,
		current.Status,
		string(domain.RideCancelled),
		domain.RideTransition{
			EventType:      domain.RideEventEmergencyStopped,
			Reason:         domain.CancellationReason(normalizedReason),
			Responsibility: domain.CancellationResponsibilitySafetyRelated,
			Details:        details,
		},
	)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("emergency stop ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": current.Status,
			"reason":          string(normalizedReason),
			"responsibility":  string(domain.CancellationResponsibilitySafetyRelated),
			"emergency_stop":  true,
			"ride":            updated,
		},
	)
	return updated, nil
}

func (service *LifecycleService) transition(
	ctx context.Context,
	rideID, actorID int,
	next string,
	transition domain.RideTransition,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for status update: %w", err)
	}
	isPassenger := current.PassengerID == actorID
	isDriver := current.DriverID != nil && *current.DriverID == actorID
	if !isPassenger && !isDriver {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	currentStatus, currentOK := domain.NormalizeRideStatus(current.Status)
	nextStatus, nextOK := domain.NormalizeRideStatus(next)
	invalidCurrentStatus := !currentOK
	invalidNextStatus := !nextOK
	if invalidCurrentStatus || invalidNextStatus {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if currentStatus == nextStatus {
		return current, nil
	}
	switch nextStatus {
	case domain.RideCancelled:
		if transition.EventType == domain.RideEventStatusChanged {
			return domain.Ride{}, domain.ErrCancellationCommand
		}
	case domain.RideArrived:
		return domain.Ride{}, domain.ErrArrivalCommand
	case domain.RideInTransit:
		return domain.Ride{}, domain.ErrTripStartCommand
	case domain.RideCompleted:
		return domain.Ride{}, domain.ErrTripCompletionCommand
	}
	if !domain.CanTransition(string(currentStatus), string(nextStatus)) {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if current.PassengerID == actorID && nextStatus != domain.RideCancelled {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	if current.DriverID == nil && nextStatus != domain.RideCancelled {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	updated, err := service.store.UpdateStatus(
		ctx,
		rideID,
		actorID,
		string(currentStatus),
		string(nextStatus),
		transition,
	)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("update ride status: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(currentStatus),
			"reason":          string(transition.Reason),
			"responsibility":  string(transition.Responsibility),
			"ride":            updated,
		},
	)
	return updated, nil
}

func (service *LifecycleService) publish(
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
