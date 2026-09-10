package database

import (
	"context"

	redisplatform "github.com/Easy-Bao/DrivingApp/server/internal/platform/redis"
	redisclient "github.com/redis/go-redis/v9"
)

// Deprecated: use redis.Open instead. This compatibility function remains so
// existing internal callers can migrate without a flag day.
func OpenRedis(redisURL string) (*redisclient.Client, error) {
	return redisplatform.Open(redisURL)
}

// Deprecated: use redis.OpenWithContext instead. This compatibility function
// remains so existing internal callers can migrate without a flag day.
func OpenRedisWithContext(ctx context.Context, redisURL string) (*redisclient.Client, error) {
	return redisplatform.OpenWithContext(ctx, redisURL)
}
