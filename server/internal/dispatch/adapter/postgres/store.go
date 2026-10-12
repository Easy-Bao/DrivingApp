package postgres

import (
	"errors"
	"log/slog"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/ports"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

const _defaultOnlinePresenceMaxAge = 45 * time.Second

type Store struct {
	pool                       *pgxpool.Pool
	queries                    *databasepostgres.Queries
	logger                     *slog.Logger
	platformCommissionBPS      int64
	onlinePresenceMaxAge       time.Duration
	allowUnverifiedTestDrivers bool
}

type StoreConfig struct {
	Pool                       *pgxpool.Pool
	Logger                     *slog.Logger
	PlatformCommissionBPS      int64
	OnlinePresenceMaxAge       time.Duration
	AllowUnverifiedTestDrivers bool
}

var _ ports.BiddingStore = (*Store)(nil)

func NewStore(config StoreConfig) (*Store, error) {
	if config.Pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	onlinePresenceMaxAge := config.OnlinePresenceMaxAge
	if onlinePresenceMaxAge <= 0 {
		onlinePresenceMaxAge = _defaultOnlinePresenceMaxAge
	}
	logger := config.Logger
	if logger == nil {
		logger = slog.Default()
	}
	return &Store{
		pool:                       config.Pool,
		queries:                    databasepostgres.New(config.Pool),
		logger:                     logger,
		platformCommissionBPS:      config.PlatformCommissionBPS,
		onlinePresenceMaxAge:       onlinePresenceMaxAge,
		allowUnverifiedTestDrivers: config.AllowUnverifiedTestDrivers,
	}, nil
}

func (store *Store) onlinePresenceCutoff() pgtype.Timestamptz {
	maxAge := store.onlinePresenceMaxAge
	if maxAge <= 0 {
		maxAge = _defaultOnlinePresenceMaxAge
	}
	return bidTimestamp(time.Now().UTC().Add(-maxAge))
}

func (store *Store) validate() error {
	if store == nil || store.pool == nil || store.queries == nil {
		return errors.New("postgresql dispatch store is not initialized")
	}
	return nil
}
