package lifecycle

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var ErrPersistenceUnavailable = errors.New("ride lifecycle persistence is unavailable")

// RideEventPublisher routes a post-persistence event for an authoritative ride.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

type Dependencies struct {
	Store       ports.RideLifecycleStore
	PublishRide RideEventPublisher
	Config      Config
}

type Service struct {
	store       ports.RideLifecycleStore
	publishRide RideEventPublisher
	config      Config
}

func NewService(dependencies Dependencies) *Service {
	return &Service{
		store:       dependencies.Store,
		publishRide: dependencies.PublishRide,
		config:      dependencies.Config,
	}
}

func (service *Service) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
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
func (service *Service) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
	return service.transition(ctx, rideID, actorID, next, domain.RideTransition{
		EventType: domain.RideEventStatusChanged,
	})
}

func (service *Service) StartTrip(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
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
	if err := domain.ValidateArrivalLocation(
		current.PickupLatitude,
		current.PickupLongitude,
		driverLatitude,
		driverLongitude,
		service.config.arrivalRadiusMeters(),
	); err != nil {
		return domain.Ride{}, err
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

func (service *Service) CompleteTrip(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
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
	if err := domain.ValidateCompletionLocation(
		current.DropoffLatitude,
		current.DropoffLongitude,
		driverLatitude,
		driverLongitude,
		service.config.completionRadiusMeters(),
	); err != nil {
		return domain.Ride{}, err
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

func (service *Service) MarkArrived(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
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

func (service *Service) MarkPassengerNoShow(
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
	if parseErr != nil || time.Now().UTC().Before(waitingUntil) {
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
func (service *Service) Cancel(ctx context.Context, request domain.CancellationRequest) (domain.Ride, error) {
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
func (service *Service) EmergencyStop(
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

func (service *Service) transition(
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

func (service *Service) publish(
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
