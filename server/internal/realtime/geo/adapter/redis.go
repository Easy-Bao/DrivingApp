package adapter

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	redis "github.com/redis/go-redis/v9"
)

type RedisRepository struct{ client *redis.Client }

func NewRedisRepository(client *redis.Client) *RedisRepository {
	return &RedisRepository{client: client}
}
func (repository *RedisRepository) Upsert(ctx context.Context, point domain.DriverPoint) error {
	payload, err := json.Marshal(point)
	if err != nil {
		return err
	}
	return repository.client.Set(ctx, fmt.Sprintf("driver:location:%s", point.DriverID), payload, 0).Err()
}
func (repository *RedisRepository) Nearby(ctx context.Context, _, _, _ float64) ([]domain.DriverPoint, error) {
	keys, err := repository.client.Keys(ctx, "driver:location:*").Result()
	if err != nil {
		return nil, err
	}
	result := make([]domain.DriverPoint, 0, len(keys))
	for _, key := range keys {
		payload, getErr := repository.client.Get(ctx, key).Bytes()
		if getErr != nil {
			continue
		}
		var point domain.DriverPoint
		if json.Unmarshal(payload, &point) == nil {
			result = append(result, point)
		}
	}
	return result, nil
}
