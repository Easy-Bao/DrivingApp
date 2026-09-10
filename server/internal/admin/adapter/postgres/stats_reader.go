package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
	adminports "github.com/Easy-Bao/DrivingApp/server/internal/admin/ports"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgxpool"
)

// StatsRepository reads admin aggregate statistics through the database.
type StatsRepository struct {
	pool    *pgxpool.Pool
	queries *databasepostgres.Queries
}

var _ adminports.StatsReader = (*StatsRepository)(nil)

func NewStatsRepository(pool *pgxpool.Pool) (*StatsRepository, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &StatsRepository{
		pool:    pool,
		queries: databasepostgres.New(pool),
	}, nil
}

// StatsReader is the canonical adapter name used by the admin composition
// root. The repository constructor remains for existing internal callers.
type StatsReader = StatsRepository

func NewStatsReader(pool *pgxpool.Pool) (*StatsReader, error) {
	return NewStatsRepository(pool)
}

func (repository *StatsRepository) Stats(ctx context.Context) (domain.Stats, error) {
	if err := repository.validate(); err != nil {
		return domain.Stats{}, err
	}

	users, err := repository.queries.CountUsers(ctx)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("count users: %w", err)
	}
	rides, err := repository.queries.CountRides(ctx)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("count rides: %w", err)
	}
	documents, err := repository.queries.CountDriverDocuments(ctx)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("count driver documents: %w", err)
	}

	userCount, err := countToInt(users)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("map user count: %w", err)
	}
	rideCount, err := countToInt(rides)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("map ride count: %w", err)
	}
	documentCount, err := countToInt(documents)
	if err != nil {
		return domain.Stats{}, fmt.Errorf("map driver document count: %w", err)
	}

	return domain.Stats{
		Users:           userCount,
		Rides:           rideCount,
		DriverDocuments: documentCount,
	}, nil
}

func (repository *StatsRepository) validate() error {
	if repository == nil || repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql stats repository is not initialized")
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
