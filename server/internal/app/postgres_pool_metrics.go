package app

import (
	"context"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

const _postgresPoolStatsInterval = 30 * time.Second

type postgresPoolSnapshot struct {
	acquireCount         int64
	acquireDuration      time.Duration
	canceledAcquireCount int64
	emptyAcquireCount    int64
	emptyAcquireWaitTime time.Duration

	acquiredConnections     int32
	idleConnections         int32
	totalConnections        int32
	constructingConnections int32
	maxConnections          int32
}

func monitorPostgresPool(ctx context.Context, logger *slog.Logger, pool *pgxpool.Pool) {
	if pool == nil {
		return
	}
	if ctx == nil {
		ctx = context.Background()
	}
	if logger == nil {
		logger = slog.Default()
	}

	previous := snapshotPostgresPool(pool)
	ticker := time.NewTicker(_postgresPoolStatsInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			current := snapshotPostgresPool(pool)
			recordPostgresPoolStats(ctx, logger, previous, current)
			return
		case <-ticker.C:
			current := snapshotPostgresPool(pool)
			recordPostgresPoolStats(ctx, logger, previous, current)
			previous = current
		}
	}
}

func snapshotPostgresPool(pool *pgxpool.Pool) postgresPoolSnapshot {
	stats := pool.Stat()
	return postgresPoolSnapshot{
		acquireCount:            stats.AcquireCount(),
		acquireDuration:         stats.AcquireDuration(),
		canceledAcquireCount:    stats.CanceledAcquireCount(),
		emptyAcquireCount:       stats.EmptyAcquireCount(),
		emptyAcquireWaitTime:    stats.EmptyAcquireWaitTime(),
		acquiredConnections:     stats.AcquiredConns(),
		idleConnections:         stats.IdleConns(),
		totalConnections:        stats.TotalConns(),
		constructingConnections: stats.ConstructingConns(),
		maxConnections:          stats.MaxConns(),
	}
}

func recordPostgresPoolStats(
	ctx context.Context,
	logger *slog.Logger,
	previous postgresPoolSnapshot,
	current postgresPoolSnapshot,
) {
	acquireCount := current.acquireCount - previous.acquireCount
	acquireDuration := current.acquireDuration - previous.acquireDuration
	averageAcquireDuration := time.Duration(0)
	if acquireCount > 0 {
		averageAcquireDuration = acquireDuration / time.Duration(acquireCount)
	}

	logger.LogAttrs(ctx, slog.LevelDebug, "postgres pool interval stats",
		slog.Int64("acquire_count", acquireCount),
		slog.Int64("acquire_duration_us", acquireDuration.Microseconds()),
		slog.Int64("average_acquire_duration_us", averageAcquireDuration.Microseconds()),
		slog.Int64("empty_acquire_count", current.emptyAcquireCount-previous.emptyAcquireCount),
		slog.Int64(
			"empty_acquire_wait_us",
			(current.emptyAcquireWaitTime-previous.emptyAcquireWaitTime).Microseconds(),
		),
		slog.Int64(
			"canceled_acquire_count",
			current.canceledAcquireCount-previous.canceledAcquireCount,
		),
		slog.Int("acquired_connections", int(current.acquiredConnections)),
		slog.Int("idle_connections", int(current.idleConnections)),
		slog.Int("total_connections", int(current.totalConnections)),
		slog.Int("constructing_connections", int(current.constructingConnections)),
		slog.Int("max_connections", int(current.maxConnections)),
	)
}
