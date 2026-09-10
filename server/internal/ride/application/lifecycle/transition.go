// Package lifecycle owns participant-authorized ride state transitions.
package lifecycle

import (
	"context"
	"errors"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var ErrPersistenceUnavailable = errors.New("ride lifecycle persistence is unavailable")

// RideEventPublisher routes a post-persistence event for an authoritative ride.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

// Dependencies collects the persistence and event seams used by lifecycle
// decisions.
type Dependencies struct {
	Store       ports.RideLifecycleStore
	PublishRide RideEventPublisher
}

// Service enforces participant authorization before persisting ride transitions.
type Service struct {
	store       ports.RideLifecycleStore
	publishRide RideEventPublisher
}

func NewService(dependencies Dependencies) *Service {
	return &Service{
		store:       dependencies.Store,
		publishRide: dependencies.PublishRide,
	}
}

// AcceptRide delegates an atomic driver-to-ride match to the lifecycle port.
func (service *Service) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	ride, err := service.store.AcceptRide(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, err
	}
	service.publish(ctx, event.RideMatched, ride, map[string]any{"ride": ride})
	return ride, nil
}

// UpdateStatus validates the current aggregate state and persists the next
// participant-authorized status.
func (service *Service) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, err
	}
	if current.PassengerID != actorID && (current.DriverID == nil || *current.DriverID != actorID) {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	currentStatus, currentOK := domain.NormalizeRideStatus(current.Status)
	nextStatus, nextOK := domain.NormalizeRideStatus(next)
	if !currentOK || !nextOK || !domain.CanTransition(string(currentStatus), string(nextStatus)) {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if current.PassengerID == actorID && nextStatus != domain.RideCancelled {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	if current.DriverID == nil && nextStatus != domain.RideCancelled {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	updated, err := service.store.UpdateStatus(ctx, rideID, actorID, string(currentStatus), string(nextStatus))
	if err != nil {
		return domain.Ride{}, err
	}
	service.publish(ctx, event.RideStatusChanged, updated, map[string]any{
		"previous_status": string(currentStatus),
		"ride":            updated,
	})
	return updated, nil
}

func (service *Service) publish(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any) {
	if service.publishRide != nil {
		service.publishRide(ctx, eventType, ride, payload)
	}
}
