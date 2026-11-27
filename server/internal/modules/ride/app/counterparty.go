package app

import (
	"context"
	"errors"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

func (service *Service) Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error) {
	if rideID <= 0 || actorID <= 0 {
		return domain.Counterparty{}, domain.ErrUnauthorizedRide
	}
	if service == nil || service.counterparties == nil {
		return domain.Counterparty{}, errors.New("ride counterparty lookup is unavailable")
	}
	counterparty, err := service.counterparties.Counterparty(ctx, rideID, actorID)
	if err != nil {
		return domain.Counterparty{}, fmt.Errorf("load ride counterparty: %w", err)
	}
	return counterparty, nil
}
