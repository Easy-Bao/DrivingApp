package adapter

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	redis "github.com/redis/go-redis/v9"
)

const (
	driverLocationsKey      = "drivers:locations"
	driverLocationKeyPrefix = "driver:location:"
	driverLocationTTL       = 45 * time.Second
	passengerLocationTTL    = 45 * time.Second
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
	_, err = repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.GeoAdd(ctx, driverLocationsKey, &redis.GeoLocation{
			Longitude: point.Longitude,
			Latitude:  point.Latitude,
			Name:      point.DriverID,
		})
		pipe.Set(
			ctx,
			driverLocationKey(point.DriverID),
			payload,
			driverLocationTTL,
		)
		return nil
	})
	return err
}
func (repository *RedisRepository) Nearby(ctx context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	locations, err := repository.client.GeoSearchLocation(ctx, driverLocationsKey, &redis.GeoSearchLocationQuery{
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
	if len(locations) == 0 {
		return []domain.DriverPoint{}, nil
	}

	keys := make([]string, 0, len(locations))
	for _, location := range locations {
		keys = append(keys, driverLocationKey(location.Name))
	}
	payloads, err := repository.client.MGet(ctx, keys...).Result()
	if err != nil {
		return nil, err
	}

	result := make([]domain.DriverPoint, 0, len(locations))
	staleLocations := make([]string, 0)
	for index, location := range locations {
		if index >= len(payloads) {
			staleLocations = append(staleLocations, location.Name)
			continue
		}
		rawPayload := payloads[index]
		payload, ok := rawPayload.(string)
		if !ok {
			staleLocations = append(staleLocations, location.Name)
			continue
		}
		var point domain.DriverPoint
		if json.Unmarshal([]byte(payload), &point) != nil ||
			point.DriverID == "" ||
			point.DriverID != location.Name {
			staleLocations = append(staleLocations, location.Name)
			continue
		}
		result = append(result, point)
	}
	if len(staleLocations) > 0 {
		// Expired payloads leave geo members behind; cleanup is best effort so a
		// transient Redis write failure does not hide valid nearby drivers.
		_ = repository.client.ZRem(ctx, driverLocationsKey, staleLocations).Err()
	}
	return result, nil
}

func (repository *RedisRepository) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	return repository.get(ctx, driverLocationKey(driverID))
}

func (repository *RedisRepository) UpsertPassenger(ctx context.Context, rideID string, point domain.DriverPoint) error {
	payload, err := json.Marshal(point)
	if err != nil {
		return err
	}
	return repository.client.Set(ctx, "passenger:location:"+rideID, payload, passengerLocationTTL).Err()
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

func driverLocationKey(driverID string) string {
	return driverLocationKeyPrefix + driverID
}
