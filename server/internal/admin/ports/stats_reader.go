package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
)

// StatsReader reads administrative aggregate statistics.
type StatsReader interface {
	Stats(ctx context.Context) (domain.Stats, error)
}
