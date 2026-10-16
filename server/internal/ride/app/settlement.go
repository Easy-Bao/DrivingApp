package app

import (
	"context"
	"errors"
	"fmt"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

var ErrSettlementPersistenceUnavailable = errors.New("cash settlement persistence is unavailable")

type SettlementDependencies struct {
	Store       CashSettlementStore
	PublishRide RideEventPublisher
}

type SettlementService struct {
	store       CashSettlementStore
	publishRide RideEventPublisher
}

func NewSettlementService(dependencies SettlementDependencies) *SettlementService {
	return &SettlementService{
		store:       dependencies.Store,
		publishRide: dependencies.PublishRide,
	}
}

func (service *SettlementService) SettleCash(ctx context.Context, request domain.CashSettlementRequest) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrSettlementPersistenceUnavailable
	}
	if request.RideID <= 0 || request.DriverID <= 0 {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	ride, err := service.store.SettleCash(ctx, request)
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

func (service *SettlementService) publish(
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
