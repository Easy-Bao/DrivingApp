package redis

import (
	"context"
	"encoding/json"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

type Cache struct {
	client *redisclient.Client
	ttl    time.Duration
}

func NewCache(client *redisclient.Client) *Cache {
	return &Cache{client: client, ttl: time.Hour}
}

func (cache *Cache) Get(ctx context.Context, key string, target any) error {
	payload, err := cache.client.Get(ctx, "location:"+key).Bytes()
	if err != nil {
		return err
	}
	return json.Unmarshal(payload, target)
}

func (cache *Cache) Set(ctx context.Context, key string, value any) error {
	payload, err := json.Marshal(value)
	if err != nil {
		return err
	}
	return cache.client.Set(ctx, "location:"+key, payload, cache.ttl).Err()
}
