package adapter

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	redis "github.com/redis/go-redis/v9"
)

const (
	driverLocationsKey       = "drivers:locations"
	driverLocationExpiryKey  = "drivers:locations:expiry"
	driverLocationKeyPrefix  = "driver:location:"
	driverLocationTTL        = 45 * time.Second
	passengerLocationTTL     = 45 * time.Second
	locationCleanupBatchSize = 100
)

const cleanupExpiredDriversScript = `
local expired = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1], 'LIMIT', '0', ARGV[2])
for _, driver_id in ipairs(expired) do
  redis.call('ZREM', KEYS[1], driver_id)
  redis.call('ZREM', KEYS[2], driver_id)
  redis.call('DEL', ARGV[3] .. driver_id)
end
return #expired
`

type DriverLocationStore struct{ client *redis.Client }

func NewDriverLocationStore(client *redis.Client) *DriverLocationStore {
	return &DriverLocationStore{client: client}
}
func (repository *DriverLocationStore) Upsert(ctx context.Context, point domain.DriverPoint) error {
	payload, err := json.Marshal(point)
	if err != nil {
		return err
	}
	expiresAt := time.Now().Add(driverLocationTTL).UnixMilli()
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
		pipe.ZAdd(ctx, driverLocationExpiryKey, redis.Z{Score: float64(expiresAt), Member: point.DriverID})
		return nil
	})
	return err
}

func (repository *DriverLocationStore) Remove(ctx context.Context, driverID string) error {
	if driverID == "" {
		return nil
	}
	_, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.ZRem(ctx, driverLocationsKey, driverID)
		pipe.ZRem(ctx, driverLocationExpiryKey, driverID)
		pipe.Del(ctx, driverLocationKey(driverID))
		return nil
	})
	return err
}
func (repository *DriverLocationStore) Nearby(ctx context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	// GEO members do not support individual TTLs. Sweep the companion expiry
	// index before searching so expired payloads cannot consume result slots.
	_ = repository.cleanupExpiredDrivers(ctx)

	// Only the member IDs are needed here. GeoSearchLocation expects a nested
	// location response when using RESP3, but Redis returns a flat member list
	// when coordinates are not requested. GeoSearch matches that response shape
	// and keeps this lookup compatible with the native Redis/Valkey setup.
	locationIDs, err := repository.client.GeoSearch(ctx, driverLocationsKey, &redis.GeoSearchQuery{
		Longitude:  longitude,
		Latitude:   latitude,
		Radius:     radiusKm,
		RadiusUnit: "km",
		Sort:       "ASC",
		Count:      20,
	}).Result()
	if err != nil {
		return nil, err
	}
	if len(locationIDs) == 0 {
		return []domain.DriverPoint{}, nil
	}

	keys := make([]string, 0, len(locationIDs))
	for _, locationID := range locationIDs {
		keys = append(keys, driverLocationKey(locationID))
	}
	payloads, err := repository.client.MGet(ctx, keys...).Result()
	if err != nil {
		return nil, err
	}

	result := make([]domain.DriverPoint, 0, len(locationIDs))
	staleLocations := make([]string, 0)
	for index, locationID := range locationIDs {
		if index >= len(payloads) {
			staleLocations = append(staleLocations, locationID)
			continue
		}
		rawPayload := payloads[index]
		payload, ok := rawPayload.(string)
		if !ok {
			staleLocations = append(staleLocations, locationID)
			continue
		}
		var point domain.DriverPoint
		if json.Unmarshal([]byte(payload), &point) != nil ||
			point.DriverID == "" ||
			point.DriverID != locationID {
			staleLocations = append(staleLocations, locationID)
			continue
		}
		result = append(result, point)
	}
	if len(staleLocations) > 0 {
		// Expired payloads leave geo members behind; cleanup is best effort so a
		// transient Redis write failure does not hide valid nearby drivers.
		_, _ = repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
			pipe.ZRem(ctx, driverLocationsKey, staleLocations)
			pipe.ZRem(ctx, driverLocationExpiryKey, staleLocations)
			return nil
		})
	}
	return result, nil
}

func (repository *DriverLocationStore) cleanupExpiredDrivers(ctx context.Context) error {
	return repository.client.Eval(
		ctx,
		cleanupExpiredDriversScript,
		[]string{driverLocationExpiryKey, driverLocationsKey},
		time.Now().UnixMilli(),
		locationCleanupBatchSize,
		driverLocationKeyPrefix,
	).Err()
}

func (repository *DriverLocationStore) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	return repository.get(ctx, driverLocationKey(driverID))
}

func (repository *DriverLocationStore) UpsertPassenger(ctx context.Context, rideID string, point domain.DriverPoint) error {
	payload, err := json.Marshal(point)
	if err != nil {
		return err
	}
	return repository.client.Set(ctx, "passenger:location:"+rideID, payload, passengerLocationTTL).Err()
}

func (repository *DriverLocationStore) GetPassenger(ctx context.Context, rideID string) (domain.DriverPoint, error) {
	return repository.get(ctx, "passenger:location:"+rideID)
}

func (repository *DriverLocationStore) get(ctx context.Context, key string) (domain.DriverPoint, error) {
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
