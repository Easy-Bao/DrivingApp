package database

import (
	"context"
	"fmt"
	"os"
	"strconv"
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

func PostgresNativePoolConfigFromEnv() PostgresNativePoolConfig {
	defaults := DefaultPostgresNativePoolConfig()
	return PostgresNativePoolConfig{
		MaxConnections:        positiveInt32Env("POSTGRES_MAX_OPEN_CONNECTIONS", defaults.MaxConnections),
		MinConnections:        nonNegativeInt32Env("POSTGRES_MIN_CONNECTIONS", defaults.MinConnections),
		MinIdleConnections:    nonNegativeInt32Env("POSTGRES_MIN_IDLE_CONNECTIONS", defaults.MinIdleConnections),
		ConnectionMaxLifetime: positiveDurationEnv("POSTGRES_CONNECTION_MAX_LIFETIME", defaults.ConnectionMaxLifetime),
		ConnectionMaxIdleTime: positiveDurationEnv("POSTGRES_CONNECTION_MAX_IDLE_TIME", defaults.ConnectionMaxIdleTime),
		PingTimeout:           positiveDurationEnv("POSTGRES_PING_TIMEOUT", defaults.PingTimeout),
	}
}

func OpenPostgresPool(databaseURL string) (*pgxpool.Pool, error) {
	return OpenPostgresPoolWithContext(
		context.Background(),
		databaseURL,
		PostgresNativePoolConfigFromEnv(),
	)
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
	if err := config.validate(); err != nil {
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

func (config PostgresNativePoolConfig) validate() error {
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
	if config.ConnectionMaxLifetime <= 0 || config.ConnectionMaxIdleTime <= 0 || config.PingTimeout <= 0 {
		return fmt.Errorf("postgresql connection durations must be positive")
	}
	return nil
}

func positiveInt32Env(key string, fallback int32) int32 {
	value := int64(positiveIntEnv(key, int(fallback)))
	if value > 1<<31-1 {
		return fallback
	}
	return int32(value)
}

func nonNegativeInt32Env(key string, fallback int32) int32 {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.ParseInt(value, 10, 32)
	if err != nil || parsed < 0 {
		return fallback
	}
	return int32(parsed)
}

func positiveIntEnv(key string, fallback int) int {
	value, err := strconv.Atoi(strings.TrimSpace(os.Getenv(key)))
	if err != nil || value <= 0 {
		return fallback
	}
	return value
}

func positiveDurationEnv(key string, fallback time.Duration) time.Duration {
	value, err := time.ParseDuration(strings.TrimSpace(os.Getenv(key)))
	if err != nil || value <= 0 {
		return fallback
	}
	return value
}
