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

func TestDefaultPostgresNativePoolConfigRecyclesConnectionsWithinThirtyMinutes(t *testing.T) {
	config := DefaultPostgresNativePoolConfig()

	if config.ConnectionMaxLifetime != 30*time.Minute {
		t.Fatalf("connection max lifetime = %s, want 30m", config.ConnectionMaxLifetime)
	}
}

func TestDefaultPostgresNativePoolConfigPrunesStaleIdleConnections(t *testing.T) {
	config := DefaultPostgresNativePoolConfig()

	if config.ConnectionMaxIdleTime != 5*time.Minute {
		t.Fatalf("connection max idle time = %s, want 5m", config.ConnectionMaxIdleTime)
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

func TestDefaultPostgresNativePoolConfigWarmIdleAndDefaultMax(t *testing.T) {
	config := DefaultPostgresNativePoolConfig()

	if config.MaxConnections < 50 {
		t.Fatalf("max connections = %d, want >= 50", config.MaxConnections)
	}
	if config.MinIdleConnections != 10 {
		t.Fatalf("min idle connections = %d, want 10", config.MinIdleConnections)
	}
	if config.MinConnections != 10 {
		t.Fatalf("min connections = %d, want 10", config.MinConnections)
	}
}

func TestDefaultPostgresNativePoolConfigReadsEnv(t *testing.T) {
	t.Setenv("DATABASE_MAX_CONNS", "120")
	t.Setenv("DATABASE_MIN_IDLE_CONNS", "20")

	config := DefaultPostgresNativePoolConfig()

	if config.MaxConnections != 120 {
		t.Fatalf("max connections = %d, want 120", config.MaxConnections)
	}
	if config.MinIdleConnections != 20 {
		t.Fatalf("min idle connections = %d, want 20", config.MinIdleConnections)
	}
	if config.MinConnections != 20 {
		t.Fatalf("min connections = %d, want 20", config.MinConnections)
	}
}
