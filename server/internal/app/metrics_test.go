package app

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"testing"
	"time"
)

func TestRecordPostgresPoolStatsLogsIntervalDeltasAndCurrentUsage(t *testing.T) {
	var output bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(
		&output,
		&slog.HandlerOptions{Level: slog.LevelDebug},
	))
	previous := postgresPoolSnapshot{
		acquireCount:         4,
		acquireDuration:      12 * time.Millisecond,
		canceledAcquireCount: 5,
		emptyAcquireCount:    2,
		emptyAcquireWaitTime: 250 * time.Microsecond,
	}
	current := postgresPoolSnapshot{
		acquireCount:            7,
		acquireDuration:         21 * time.Millisecond,
		canceledAcquireCount:    7,
		emptyAcquireCount:       4,
		emptyAcquireWaitTime:    750 * time.Microsecond,
		acquiredConnections:     4,
		idleConnections:         3,
		totalConnections:        7,
		constructingConnections: 1,
		maxConnections:          10,
	}

	recordPostgresPoolStats(context.Background(), logger, previous, current)

	var fields map[string]any
	if err := json.Unmarshal(output.Bytes(), &fields); err != nil {
		t.Fatalf("decode pool stats log: %v", err)
	}
	if fields["msg"] != "postgres pool interval stats" {
		t.Fatalf("log message = %v", fields["msg"])
	}
	assertPostgresPoolMetric(t, fields, "acquire_count", 3)
	assertPostgresPoolMetric(t, fields, "acquire_duration_us", 9000)
	assertPostgresPoolMetric(t, fields, "average_acquire_duration_us", 3000)
	assertPostgresPoolMetric(t, fields, "empty_acquire_count", 2)
	assertPostgresPoolMetric(t, fields, "empty_acquire_wait_us", 500)
	assertPostgresPoolMetric(t, fields, "canceled_acquire_count", 2)
	assertPostgresPoolMetric(t, fields, "acquired_connections", 4)
	assertPostgresPoolMetric(t, fields, "idle_connections", 3)
	assertPostgresPoolMetric(t, fields, "total_connections", 7)
	assertPostgresPoolMetric(t, fields, "constructing_connections", 1)
	assertPostgresPoolMetric(t, fields, "max_connections", 10)
}

func assertPostgresPoolMetric(t *testing.T, fields map[string]any, name string, want int64) {
	t.Helper()
	value, ok := fields[name].(float64)
	if !ok || int64(value) != want {
		t.Fatalf("%s = %v, want %d", name, fields[name], want)
	}
}
