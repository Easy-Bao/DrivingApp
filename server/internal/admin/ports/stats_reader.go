package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
)

// StatsReader isolates admin reporting from its persistence adapter.
type StatsReader interface {
	Stats(ctx context.Context) (domain.Stats, error)
}
