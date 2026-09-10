package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// DriverAvailabilityReader supplies bounded driver projections for dispatch and
// passenger views.
type DriverAvailabilityReader interface {
	OnlineDrivers(ctx context.Context, driverIDs []int) ([]domain.OnlineDriver, error)
	PublicDriverSummaries(ctx context.Context, limit int) ([]domain.PublicDriverSummary, error)
}
