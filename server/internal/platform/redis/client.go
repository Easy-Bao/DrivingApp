package redis

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

func Open(redisURL string) (*redisclient.Client, error) {
	return OpenWithContext(context.Background(), redisURL)
}

func OpenWithContext(ctx context.Context, redisURL string) (*redisclient.Client, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if strings.TrimSpace(redisURL) == "" {
		return nil, fmt.Errorf("redis URL is required")
	}
	options, err := redisclient.ParseURL(redisURL)
	if err != nil {
		return nil, fmt.Errorf("parse redis URL: %w", err)
	}
	client := redisclient.NewClient(options)
	pingContext, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := client.Ping(pingContext).Err(); err != nil {
		pingErr := fmt.Errorf("ping redis: %w", err)
		if closeErr := client.Close(); closeErr != nil {
			return nil, errors.Join(
				pingErr,
				fmt.Errorf("close redis after failed ping: %w", closeErr),
			)
		}
		return nil, pingErr
	}
	return client, nil
}

// Deprecated: use Open instead.
func OpenRedis(redisURL string) (*redisclient.Client, error) {
	return Open(redisURL)
}

// Deprecated: use OpenWithContext instead.
func OpenRedisWithContext(ctx context.Context, redisURL string) (*redisclient.Client, error) {
	return OpenWithContext(ctx, redisURL)
}
