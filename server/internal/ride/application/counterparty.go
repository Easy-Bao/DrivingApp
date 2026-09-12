package application

import (
	"context"
	"errors"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

func (service *RideService) Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error) {
	if rideID <= 0 || actorID <= 0 {
		return domain.Counterparty{}, domain.ErrUnauthorizedRide
	}
	repository, ok := service.repository.(ports.CounterpartyReader)
	if !ok {
		return domain.Counterparty{}, errors.New("ride counterparty lookup is unavailable")
	}
	counterparty, err := repository.Counterparty(ctx, rideID, actorID)
	if err != nil {
		return domain.Counterparty{}, fmt.Errorf("load ride counterparty: %w", err)
	}
	return counterparty, nil
}
