package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// DriverAvailabilityReader exposes public and targeted online-driver views.
type DriverAvailabilityReader interface {
	OnlineDrivers(ctx context.Context, driverIDs []int) ([]domain.OnlineDriver, error)
	PublicDriverSummaries(ctx context.Context, limit int) ([]domain.PublicDriverSummary, error)
}
