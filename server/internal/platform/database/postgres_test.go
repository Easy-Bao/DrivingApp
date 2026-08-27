package database

import (
	"testing"
	"time"
)

func TestNormalizePostgresURLDisablesTLSForLocalHosts(t *testing.T) {
	value := NormalizePostgresURL("postgres://user:pass@localhost:5432/app?sslmode=require")
	if value != "postgres://user:pass@localhost:5432/app?sslmode=disable" {
		t.Fatalf("normalized local URL = %q", value)
	}
}

func TestNormalizePostgresURLKeepsRemoteTLSConfiguration(t *testing.T) {
	value := NormalizePostgresURL("postgres://user:pass@db.example.test:5432/app?sslmode=require")
	if value != "postgres://user:pass@db.example.test:5432/app?sslmode=require" {
		t.Fatalf("normalized remote URL = %q", value)
	}
}

func TestPostgresPoolConfigFromEnv(t *testing.T) {
	t.Setenv("POSTGRES_MAX_OPEN_CONNECTIONS", "40")
	t.Setenv("POSTGRES_MAX_IDLE_CONNECTIONS", "12")
	t.Setenv("POSTGRES_CONNECTION_MAX_LIFETIME", "45m")
	t.Setenv("POSTGRES_CONNECTION_MAX_IDLE_TIME", "8m")
	t.Setenv("POSTGRES_PING_TIMEOUT", "3s")

	config := PostgresPoolConfigFromEnv()
	if config.MaxOpenConnections != 40 || config.MaxIdleConnections != 12 {
		t.Fatalf("pool sizes = %d/%d", config.MaxOpenConnections, config.MaxIdleConnections)
	}
	if config.ConnectionMaxLifetime != 45*time.Minute ||
		config.ConnectionMaxIdleTime != 8*time.Minute ||
		config.PingTimeout != 3*time.Second {
		t.Fatalf("pool durations = %s/%s/%s", config.ConnectionMaxLifetime, config.ConnectionMaxIdleTime, config.PingTimeout)
	}
}

func TestOpenPostgresRejectsInvalidPoolConfigBeforeConnecting(t *testing.T) {
	config := DefaultPostgresPoolConfig()
	config.MaxOpenConnections = 2
	config.MaxIdleConnections = 3

	if _, err := OpenPostgresWithConfig("postgres://localhost/test", config); err == nil {
		t.Fatal("expected invalid pool configuration to fail")
	}
}
