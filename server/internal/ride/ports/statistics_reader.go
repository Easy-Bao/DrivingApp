package ports

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// DriverStatisticsReader isolates dashboard reads from ride command persistence.
type DriverStatisticsReader interface {
	DriverStats(ctx context.Context, driverID int, dayStart, dayEnd time.Time) (domain.DriverStats, error)
}
