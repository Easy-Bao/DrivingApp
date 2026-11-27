package app

import (
	"context"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"strings"
)

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
	return service.transitionFrom(ctx, current, request.ActorID, string(domain.RideCancelled), domain.RideTransition{
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
	return service.transitionFrom(ctx, current, actorID, next, transition)
}

func (service *LifecycleService) transitionFrom(
	ctx context.Context,
	current domain.Ride,
	actorID int,
	next string,
	transition domain.RideTransition,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
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
		current.ID,
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
