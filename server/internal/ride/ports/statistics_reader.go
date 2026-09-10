package ports

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// DriverStatisticsReader exposes the read-only driver statistics projection.
type DriverStatisticsReader interface {
	DriverStats(ctx context.Context, driverID int, dayStart, dayEnd time.Time) (domain.DriverStats, error)
}
