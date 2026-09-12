package redis

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	locationports "github.com/Easy-Bao/DrivingApp/server/internal/location/ports"
	redisclient "github.com/redis/go-redis/v9"
)

type Cache struct {
	client *redisclient.Client
	ttl    time.Duration
}

var _ locationports.Cache = (*Cache)(nil)

func NewCache(client *redisclient.Client) *Cache {
	return &Cache{client: client, ttl: time.Hour}
}

func (cache *Cache) Get(ctx context.Context, key string, target any) error {
	if cache == nil || cache.client == nil {
		return errors.New("location cache is not configured")
	}
	payload, err := cache.client.Get(ctx, "location:"+key).Bytes()
	if errors.Is(err, redisclient.Nil) {
		return locationports.ErrCacheMiss
	}
	if err != nil {
		return fmt.Errorf("get location cache entry: %w", err)
	}
	if err := json.Unmarshal(payload, target); err != nil {
		return fmt.Errorf("decode location cache entry: %w", err)
	}
	return nil
}

func (cache *Cache) Set(ctx context.Context, key string, value any) error {
	if cache == nil || cache.client == nil {
		return errors.New("location cache is not configured")
	}
	payload, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("marshal location cache entry: %w", err)
	}
	if err := cache.client.Set(
		ctx,
		"location:"+key,
		payload,
		cache.ttl,
	).Err(); err != nil {
		return fmt.Errorf("store location cache entry: %w", err)
	}
	return nil
}
