package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
)

// DriverAvailabilityReader supplies bounded availability and public driver projections.
type DriverAvailabilityReader interface {
	OnlineDrivers(ctx context.Context, driverIDs []int) ([]domain.OnlineDriver, error)
	PublicDriverSummaries(ctx context.Context, limit int) ([]domain.PublicDriverSummary, error)
}
