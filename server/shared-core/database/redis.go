package database

import (
	"context"
	"fmt"
	"strings"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

func OpenRedis(redisURL string) (*redisclient.Client, error) {
	if strings.TrimSpace(redisURL) == "" {
		return nil, fmt.Errorf("redis URL is required")
	}
	options, err := redisclient.ParseURL(redisURL)
	if err != nil {
		return nil, err
	}
	client := redisclient.NewClient(options)
	pingContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := client.Ping(pingContext).Err(); err != nil {
		_ = client.Close()
		return nil, fmt.Errorf("ping Redis: %w", err)
	}
	return client, nil
}
