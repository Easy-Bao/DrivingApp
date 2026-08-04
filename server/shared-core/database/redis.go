package database

import (
	"context"
	"fmt"

	redisclient "github.com/redis/go-redis/v9"
)

func OpenRedis(redisURL string) (*redisclient.Client, error) {
	if redisURL == "" {
		return nil, fmt.Errorf("redis URL is required")
	}
	options, err := redisclient.ParseURL(redisURL)
	if err != nil {
		return nil, err
	}
	client := redisclient.NewClient(options)
	if err := client.Ping(context.Background()).Err(); err != nil {
		_ = client.Close()
		return nil, err
	}
	return client, nil
}
