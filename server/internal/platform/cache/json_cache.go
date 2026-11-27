package cache

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

// ErrCacheMiss indicates that the requested cache key does not exist in Redis.
var ErrCacheMiss = errors.New("cache miss")

// GetJSON loads and decodes a JSON value from Redis into T.
// It returns ErrCacheMiss when the key does not exist.
func GetJSON[T any](ctx context.Context, client *redisclient.Client, key string) (T, error) {
	var zero T
	if client == nil {
		return zero, errors.New("redis cache client is not configured")
	}
	payload, err := client.Get(ctx, key).Bytes()
	if errors.Is(err, redisclient.Nil) {
		return zero, ErrCacheMiss
	}
	if err != nil {
		return zero, fmt.Errorf("get cached value %q: %w", key, err)
	}
	var value T
	if err := json.Unmarshal(payload, &value); err != nil {
		return zero, fmt.Errorf("decode cached value %q: %w", key, err)
	}
	return value, nil
}

// SetJSON marshals value as JSON and writes it to Redis with the specified TTL.
func SetJSON(ctx context.Context, client *redisclient.Client, key string, value any, ttl time.Duration) error {
	if client == nil {
		return errors.New("redis cache client is not configured")
	}
	payload, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("marshal cached value %q: %w", key, err)
	}
	if err := client.Set(ctx, key, payload, ttl).Err(); err != nil {
		return fmt.Errorf("store cached value %q: %w", key, err)
	}
	return nil
}
