package ports

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// DriverEarningsReader exposes the read-only earnings projection.
type DriverEarningsReader interface {
	DriverEarnings(ctx context.Context, driverID int, monthStart, monthEnd time.Time) ([]domain.DriverEarning, error)
}
