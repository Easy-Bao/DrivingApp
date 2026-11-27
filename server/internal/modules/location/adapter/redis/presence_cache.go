package redis

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

const (
	_presenceKeyPrefix    = "driver:online:"
	_defaultPresenceTTL   = 45 * time.Second
	_fallbackPresenceTTL  = 5 * time.Second
	_presenceWriteTimeout = time.Second
)

type presenceKVStore interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key, value string, expiration time.Duration) error
}

type goRedisPresenceKV struct {
	client *redisclient.Client
}

func (store goRedisPresenceKV) Get(ctx context.Context, key string) (string, error) {
	return store.client.Get(ctx, key).Result()
}

func (store goRedisPresenceKV) Set(ctx context.Context, key, value string, expiration time.Duration) error {
	return store.client.Set(ctx, key, value, expiration).Err()
}

// PostgresPresenceReader loads authoritative driver online presence on cache miss.
type PostgresPresenceReader func(ctx context.Context, userID int, maxAge time.Duration) (bool, error)

// DriverPresenceCache caches driver online state in Redis to keep high-frequency
// GPS ingestion off PostgreSQL while falling back to PostgreSQL on cache miss or outage.
type DriverPresenceCache struct {
	kv       presenceKVStore
	fallback PostgresPresenceReader
	maxAge   time.Duration
	logger   *slog.Logger
}

func NewDriverPresenceCache(
	client *redisclient.Client,
	fallback PostgresPresenceReader,
	maxAge time.Duration,
	logger *slog.Logger,
) *DriverPresenceCache {
	var kv presenceKVStore
	if client != nil {
		kv = goRedisPresenceKV{client: client}
	}
	return newDriverPresenceCacheWithKV(kv, fallback, maxAge, logger)
}

func newDriverPresenceCacheWithKV(
	kv presenceKVStore,
	fallback PostgresPresenceReader,
	maxAge time.Duration,
	logger *slog.Logger,
) *DriverPresenceCache {
	if maxAge <= 0 {
		maxAge = _defaultPresenceTTL
	}
	if logger == nil {
		logger = slog.Default()
	}
	return &DriverPresenceCache{
		kv:       kv,
		fallback: fallback,
		maxAge:   maxAge,
		logger:   logger,
	}
}

func (cache *DriverPresenceCache) SetOnline(ctx context.Context, driverID int, isOnline bool) {
	if cache == nil || cache.kv == nil || driverID <= 0 {
		return
	}
	baseCtx := ctx
	if baseCtx == nil {
		baseCtx = context.Background()
	}
	writeCtx, cancel := context.WithTimeout(context.WithoutCancel(baseCtx), _presenceWriteTimeout)
	defer cancel()

	value := "0"
	if isOnline {
		value = "1"
	}
	if err := cache.kv.Set(writeCtx, presenceKey(strconv.Itoa(driverID)), value, cache.maxAge); err != nil {
		cache.log().WarnContext(ctx, "update redis driver online presence cache failed", "error", err)
	}
}

func (cache *DriverPresenceCache) IsOnline(ctx context.Context, driverID string) (bool, error) {
	if cache == nil {
		return false, errors.New("driver presence cache is not configured")
	}
	parsedID, err := strconv.Atoi(driverID)
	if err != nil || parsedID <= 0 {
		return false, fmt.Errorf("parse driver id: %w", err)
	}
	if cache.kv != nil {
		raw, cacheErr := cache.kv.Get(ctx, presenceKey(strconv.Itoa(parsedID)))
		if cacheErr == nil {
			if raw == "1" {
				return true, nil
			}
			if raw == "0" {
				return false, nil
			}
		} else if !errors.Is(cacheErr, redisclient.Nil) {
			if errors.Is(cacheErr, context.Canceled) || errors.Is(cacheErr, context.DeadlineExceeded) {
				return false, cacheErr
			}
			cache.log().WarnContext(ctx, "read redis driver online presence failed; falling back to postgresql", "error", cacheErr)
		}
	}
	if cache.fallback == nil {
		return false, errors.New("postgresql presence fallback is unavailable")
	}
	online, err := cache.fallback(ctx, parsedID, cache.maxAge)
	if err != nil {
		return false, err
	}
	if cache.kv != nil {
		value := "0"
		if online {
			value = "1"
		}
		if err := cache.kv.Set(ctx, presenceKey(strconv.Itoa(parsedID)), value, min(cache.maxAge, _fallbackPresenceTTL)); err != nil {
			cache.log().DebugContext(ctx, "populate driver presence cache failed", "error", err)
		}
	}
	return online, nil
}

func (cache *DriverPresenceCache) log() *slog.Logger {
	if cache != nil && cache.logger != nil {
		return cache.logger
	}
	return slog.Default()
}

func presenceKey(driverID string) string {
	return _presenceKeyPrefix + driverID
}
