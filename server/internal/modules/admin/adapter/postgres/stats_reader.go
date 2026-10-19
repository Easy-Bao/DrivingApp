package postgres

import (
	"context"
	"errors"
	"fmt"

	adminapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/domain"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5/pgxpool"
)

type StatsReader struct {
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var _ adminapp.StatsReader = (*StatsReader)(nil)

func NewStatsReader(pool *pgxpool.Pool) (*StatsReader, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &StatsReader{
		pool:    pool,
		queries: databasepostgres.New(pool),
	}, nil
}

func (reader *StatsReader) Stats(ctx context.Context) (domain.Stats, error) {
	if err := reader.validate(); err != nil {
		return domain.Stats{}, err
	}

	counts, err := reader.queries.GetAdminDashboardCounts(ctx)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("read dashboard counts: %w", err)
	}

	userCount, err := countToInt(counts.UsersCount)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("map user count: %w", err)
	}
	rideCount, err := countToInt(counts.RidesCount)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("map ride count: %w", err)
	}
	documentCount, err := countToInt(counts.DriverDocumentsCount)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("map driver document count: %w", err)
	}

	return domain.Stats{
		Users:           userCount,
		Rides:           rideCount,
		DriverDocuments: documentCount,
	}, nil
}

func (reader *StatsReader) validate() error {
	if reader == nil {
		return errors.New("postgresql stats reader is not initialized")
	}
	if reader.pool == nil || reader.queries == nil {
		return errors.New("postgresql stats reader is not initialized")
	}
	return nil
}

func countToInt(value int64) (int, error) {
	if value < 0 {
		return 0, fmt.Errorf("count cannot be negative: %d", value)
	}
	if uint64(value) > uint64(^uint(0)>>1) {
		return 0, fmt.Errorf("count %d exceeds native integer range", value)
	}
	return int(value), nil
}
