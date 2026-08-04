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
	if err := repository.client.GeoAdd(ctx, "drivers:locations", &redis.GeoLocation{Longitude: point.Longitude, Latitude: point.Latitude, Name: point.DriverID}).Err(); err != nil {
		return err
	}
	return repository.client.Set(ctx, fmt.Sprintf("driver:location:%s", point.DriverID), payload, 0).Err()
}
func (repository *RedisRepository) Nearby(ctx context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	locations, err := repository.client.GeoSearchLocation(ctx, "drivers:locations", &redis.GeoSearchLocationQuery{
		GeoSearchQuery: redis.GeoSearchQuery{
			Longitude:  longitude,
			Latitude:   latitude,
			Radius:     radiusKm,
			RadiusUnit: "km",
		},
		WithCoord: false,
	}).Result()
	if err != nil {
		return nil, err
	}
	result := make([]domain.DriverPoint, 0, len(locations))
	for _, location := range locations {
		payload, getErr := repository.client.Get(ctx, fmt.Sprintf("driver:location:%s", location.Name)).Bytes()
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

func (repository *RedisRepository) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	return repository.get(ctx, "driver:location:"+driverID)
}

func (repository *RedisRepository) UpsertPassenger(ctx context.Context, rideID string, point domain.DriverPoint) error {
	payload, err := json.Marshal(point)
	if err != nil {
		return err
	}
	return repository.client.Set(ctx, "passenger:location:"+rideID, payload, 0).Err()
}

func (repository *RedisRepository) GetPassenger(ctx context.Context, rideID string) (domain.DriverPoint, error) {
	return repository.get(ctx, "passenger:location:"+rideID)
}

func (repository *RedisRepository) get(ctx context.Context, key string) (domain.DriverPoint, error) {
	payload, err := repository.client.Get(ctx, key).Bytes()
	if err != nil {
		return domain.DriverPoint{}, err
	}
	var point domain.DriverPoint
	if err := json.Unmarshal(payload, &point); err != nil {
		return domain.DriverPoint{}, err
	}
	return point, nil
}
