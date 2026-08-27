package usecase

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

func (service *RideService) Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error) {
	if rideID <= 0 || actorID <= 0 {
		return domain.Counterparty{}, domain.ErrUnauthorizedRide
	}
	repository, ok := service.repository.(domain.CounterpartyRepository)
	if !ok {
		return domain.Counterparty{}, errors.New("ride counterparty lookup is unavailable")
	}
	return repository.Counterparty(ctx, rideID, actorID)
}
