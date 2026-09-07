package database

import (
	"context"
	"testing"
	"time"
)

func TestOpenPostgresPoolWithContextStopsBeforeOpeningWhenCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := OpenPostgresPoolWithContext(
		ctx,
		"postgres://localhost/test",
		DefaultPostgresNativePoolConfig(),
	)
	if err != context.Canceled {
		t.Fatalf("error = %v, want context canceled", err)
	}
}

func TestOpenPostgresPoolRejectsInvalidConfigBeforeConnecting(t *testing.T) {
	config := DefaultPostgresNativePoolConfig()
	config.MinIdleConnections = config.MaxConnections + 1

	_, err := OpenPostgresPoolWithConfig("postgres://localhost/test", config)
	if err == nil {
		t.Fatal("expected invalid pool configuration to fail")
	}
}

func TestPostgresNativePoolConfigFromEnv(t *testing.T) {
	t.Setenv("POSTGRES_MAX_OPEN_CONNECTIONS", "40")
	t.Setenv("POSTGRES_MIN_CONNECTIONS", "4")
	t.Setenv("POSTGRES_MIN_IDLE_CONNECTIONS", "8")
	t.Setenv("POSTGRES_CONNECTION_MAX_LIFETIME", "45m")
	t.Setenv("POSTGRES_CONNECTION_MAX_IDLE_TIME", "8m")
	t.Setenv("POSTGRES_PING_TIMEOUT", "3s")

	config := PostgresNativePoolConfigFromEnv()
	if config.MaxConnections != 40 || config.MinConnections != 4 || config.MinIdleConnections != 8 {
		t.Fatalf("pool sizes = %d/%d/%d", config.MaxConnections, config.MinConnections, config.MinIdleConnections)
	}
	if config.ConnectionMaxLifetime != 45*time.Minute ||
		config.ConnectionMaxIdleTime != 8*time.Minute ||
		config.PingTimeout != 3*time.Second {
		t.Fatalf("pool durations = %s/%s/%s", config.ConnectionMaxLifetime, config.ConnectionMaxIdleTime, config.PingTimeout)
	}
}
