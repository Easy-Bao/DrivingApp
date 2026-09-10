package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// CashSettlementStore records cash settlement for a completed ride.
type CashSettlementStore interface {
	SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error)
}
