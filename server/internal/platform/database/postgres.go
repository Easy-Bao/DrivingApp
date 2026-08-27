package database

import (
	"context"
	"fmt"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"entgo.io/ent/dialect"
	entsql "entgo.io/ent/dialect/sql"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	_ "github.com/lib/pq"
)

type PostgresPoolConfig struct {
	MaxOpenConnections    int
	MaxIdleConnections    int
	ConnectionMaxLifetime time.Duration
	ConnectionMaxIdleTime time.Duration
	PingTimeout           time.Duration
}

// PostgresConnection keeps the Ent client and its dialect driver together.
// The migration runner uses the driver to keep PostgreSQL-specific schema work
// on the same Ent-owned transaction as the migration ledger.
type PostgresConnection struct {
	Client *ent.Client
	Driver dialect.Driver
}

func DefaultPostgresPoolConfig() PostgresPoolConfig {
	return PostgresPoolConfig{
		MaxOpenConnections:    25,
		MaxIdleConnections:    10,
		ConnectionMaxLifetime: 30 * time.Minute,
		ConnectionMaxIdleTime: 5 * time.Minute,
		PingTimeout:           5 * time.Second,
	}
}

func PostgresPoolConfigFromEnv() PostgresPoolConfig {
	defaults := DefaultPostgresPoolConfig()
	return PostgresPoolConfig{
		MaxOpenConnections:    positiveIntEnv("POSTGRES_MAX_OPEN_CONNECTIONS", defaults.MaxOpenConnections),
		MaxIdleConnections:    positiveIntEnv("POSTGRES_MAX_IDLE_CONNECTIONS", defaults.MaxIdleConnections),
		ConnectionMaxLifetime: positiveDurationEnv("POSTGRES_CONNECTION_MAX_LIFETIME", defaults.ConnectionMaxLifetime),
		ConnectionMaxIdleTime: positiveDurationEnv("POSTGRES_CONNECTION_MAX_IDLE_TIME", defaults.ConnectionMaxIdleTime),
		PingTimeout:           positiveDurationEnv("POSTGRES_PING_TIMEOUT", defaults.PingTimeout),
	}
}

func OpenPostgres(databaseURL string) (*ent.Client, error) {
	connection, err := OpenPostgresConnectionWithConfig(databaseURL, PostgresPoolConfigFromEnv())
	if err != nil {
		return nil, err
	}
	return connection.Client, nil
}

func OpenPostgresWithConfig(databaseURL string, config PostgresPoolConfig) (*ent.Client, error) {
	connection, err := OpenPostgresConnectionWithConfig(databaseURL, config)
	if err != nil {
		return nil, err
	}
	return connection.Client, nil
}

func OpenPostgresConnection(databaseURL string) (*PostgresConnection, error) {
	return OpenPostgresConnectionWithConfig(databaseURL, PostgresPoolConfigFromEnv())
}

func OpenPostgresConnectionWithConfig(databaseURL string, config PostgresPoolConfig) (*PostgresConnection, error) {
	if strings.TrimSpace(databaseURL) == "" {
		return nil, fmt.Errorf("database URL is required")
	}
	if err := config.validate(); err != nil {
		return nil, err
	}
	databaseURL = NormalizePostgresURL(strings.TrimSpace(databaseURL))
	driver, err := entsql.Open(dialect.Postgres, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("open postgresql connection: %w", err)
	}
	pool := driver.DB()
	pool.SetMaxOpenConns(config.MaxOpenConnections)
	pool.SetMaxIdleConns(config.MaxIdleConnections)
	pool.SetConnMaxLifetime(config.ConnectionMaxLifetime)
	pool.SetConnMaxIdleTime(config.ConnectionMaxIdleTime)

	pingContext, cancel := context.WithTimeout(context.Background(), config.PingTimeout)
	defer cancel()
	if err := pool.PingContext(pingContext); err != nil {
		_ = driver.Close()
		return nil, fmt.Errorf("ping postgresql: %w", err)
	}

	return &PostgresConnection{
		Client: ent.NewClient(ent.Driver(driver)),
		Driver: driver,
	}, nil
}

func (config PostgresPoolConfig) validate() error {
	if config.MaxOpenConnections <= 0 {
		return fmt.Errorf("postgresql max open connections must be positive")
	}
	if config.MaxIdleConnections <= 0 {
		return fmt.Errorf("postgresql max idle connections must be positive")
	}
	if config.MaxIdleConnections > config.MaxOpenConnections {
		return fmt.Errorf("postgresql max idle connections cannot exceed max open connections")
	}
	if config.ConnectionMaxLifetime <= 0 || config.ConnectionMaxIdleTime <= 0 || config.PingTimeout <= 0 {
		return fmt.Errorf("postgresql connection durations must be positive")
	}
	return nil
}

// NormalizePostgresURL makes local Compose connections explicit about TLS.
// Production URLs keep their configured SSL mode unchanged.
func NormalizePostgresURL(databaseURL string) string {
	parsed, err := url.Parse(databaseURL)
	if err != nil {
		return databaseURL
	}
	host := parsed.Hostname()
	if host != "localhost" && host != "127.0.0.1" && host != "postgres-db" {
		return databaseURL
	}
	query := parsed.Query()
	query.Set("sslmode", "disable")
	parsed.RawQuery = query.Encode()
	return parsed.String()
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
