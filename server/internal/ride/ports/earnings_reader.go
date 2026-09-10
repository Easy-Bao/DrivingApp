package ports

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// DriverEarningsReader isolates reporting reads from ride command persistence.
type DriverEarningsReader interface {
	DriverEarnings(ctx context.Context, driverID int, monthStart, monthEnd time.Time) ([]domain.DriverEarning, error)
}
