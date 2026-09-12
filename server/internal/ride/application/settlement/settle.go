// Package settlement owns ride cash-settlement use cases.
package settlement

import (
	"context"
	"errors"
	"fmt"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var ErrPersistenceUnavailable = errors.New("cash settlement persistence is unavailable")

// RideEventPublisher routes a post-persistence event for an authoritative ride.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

// Dependencies collects the settlement persistence and event seams.
type Dependencies struct {
	Store       ports.CashSettlementStore
	PublishRide RideEventPublisher
}

// Service validates and records cash settlement at the application boundary.
type Service struct {
	store       ports.CashSettlementStore
	publishRide RideEventPublisher
}

func NewService(dependencies Dependencies) *Service {
	return &Service{
		store:       dependencies.Store,
		publishRide: dependencies.PublishRide,
	}
}

// SettleCash records the driver's cash settlement after validating the actor.
func (service *Service) SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	if driverID <= 0 {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	ride, err := service.store.SettleCash(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("settle ride cash payment: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		ride,
		map[string]any{
			"ride":           ride,
			"payment_status": ride.PaymentStatus,
		},
	)
	return ride, nil
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
