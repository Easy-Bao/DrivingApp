package database

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// PostgresNativePoolConfig controls native PostgreSQL pool limits and
// connection lifetimes.
type PostgresNativePoolConfig struct {
	MaxConnections int32
	MinConnections int32
	// MinIdleConnections keeps warm connections available without treating an
	// idle connection count as a hard upper bound.
	MinIdleConnections    int32
	ConnectionMaxLifetime time.Duration
	ConnectionMaxIdleTime time.Duration
	PingTimeout           time.Duration
}

func DefaultPostgresNativePoolConfig() PostgresNativePoolConfig {
	return PostgresNativePoolConfig{
		MaxConnections:        25,
		MinConnections:        0,
		MinIdleConnections:    0,
		ConnectionMaxLifetime: 30 * time.Minute,
		ConnectionMaxIdleTime: 5 * time.Minute,
		PingTimeout:           5 * time.Second,
	}
}

func OpenPostgresPoolWithConfig(databaseURL string, config PostgresNativePoolConfig) (*pgxpool.Pool, error) {
	return OpenPostgresPoolWithContext(context.Background(), databaseURL, config)
}

// OpenPostgresPoolWithContext opens a native pool and verifies its first
// connection before returning ownership to the caller.
func OpenPostgresPoolWithContext(
	ctx context.Context,
	databaseURL string,
	config PostgresNativePoolConfig,
) (*pgxpool.Pool, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if strings.TrimSpace(databaseURL) == "" {
		return nil, fmt.Errorf("database URL is required")
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}

	poolConfig, err := pgxpool.ParseConfig(NormalizePostgresURL(strings.TrimSpace(databaseURL)))
	if err != nil {
		return nil, fmt.Errorf("parse postgresql pool configuration: %w", err)
	}
	poolConfig.MaxConns = config.MaxConnections
	poolConfig.MinConns = config.MinConnections
	poolConfig.MinIdleConns = config.MinIdleConnections
	poolConfig.MaxConnLifetime = config.ConnectionMaxLifetime
	poolConfig.MaxConnIdleTime = config.ConnectionMaxIdleTime
	poolConfig.PingTimeout = config.PingTimeout

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, fmt.Errorf("open postgresql pool: %w", err)
	}

	pingContext, cancel := context.WithTimeout(ctx, config.PingTimeout)
	defer cancel()
	if err := pool.Ping(pingContext); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping postgresql pool: %w", err)
	}

	return pool, nil
}

func (config PostgresNativePoolConfig) Validate() error {
	if config.MaxConnections <= 0 {
		return fmt.Errorf("postgresql max connections must be positive")
	}
	if config.MinConnections < 0 {
		return fmt.Errorf("postgresql min connections cannot be negative")
	}
	if config.MinConnections > config.MaxConnections {
		return fmt.Errorf("postgresql min connections cannot exceed max connections")
	}
	if config.MinIdleConnections < 0 {
		return fmt.Errorf("postgresql min idle connections cannot be negative")
	}
	if config.MinIdleConnections > config.MaxConnections {
		return fmt.Errorf("postgresql min idle connections cannot exceed max connections")
	}
	invalidConnectionLifetime := config.ConnectionMaxLifetime <= 0
	invalidIdleTime := config.ConnectionMaxIdleTime <= 0
	invalidPingTimeout := config.PingTimeout <= 0
	if invalidConnectionLifetime || invalidIdleTime || invalidPingTimeout {
		return fmt.Errorf("postgresql connection durations must be positive")
	}
	return nil
}
