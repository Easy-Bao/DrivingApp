package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// CashSettlementStore is the atomic boundary for recording driver cash
// settlement on completed rides.
type CashSettlementStore interface {
	SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error)
}
