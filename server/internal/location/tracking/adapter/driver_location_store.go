package adapter

import (
	"context"
	jsonv2 "encoding/json/v2"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
	trackingports "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/ports"
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

type DriverLocationStore struct {
	client *redis.Client
	logger *slog.Logger
}

var _ trackingports.LocationStore = (*DriverLocationStore)(nil)

func NewDriverLocationStore(client *redis.Client) *DriverLocationStore {
	return &DriverLocationStore{client: client, logger: slog.Default()}
}

func (repository *DriverLocationStore) WithLogger(logger *slog.Logger) *DriverLocationStore {
	if repository != nil && logger != nil {
		repository.logger = logger
	}
	return repository
}

func (repository *DriverLocationStore) log() *slog.Logger {
	if repository != nil && repository.logger != nil {
		return repository.logger
	}
	return slog.Default()
}

func (repository *DriverLocationStore) Upsert(ctx context.Context, point domain.DriverPoint) error {
	if err := repository.validate(); err != nil {
		return err
	}
	payload, err := jsonv2.Marshal(point)
	if err != nil {
		return fmt.Errorf("marshal driver location: %w", err)
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
	if err != nil {
		return fmt.Errorf("persist driver location transaction: %w", err)
	}
	return nil
}

func (repository *DriverLocationStore) Remove(ctx context.Context, driverID string) error {
	if driverID == "" {
		return nil
	}
	if err := repository.validate(); err != nil {
		return err
	}
	_, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.ZRem(ctx, driverLocationsKey, driverID)
		pipe.ZRem(ctx, driverLocationExpiryKey, driverID)
		pipe.Del(ctx, driverLocationKey(driverID))
		return nil
	})
	if err != nil {
		return fmt.Errorf("remove driver location transaction: %w", err)
	}
	return nil
}
func (repository *DriverLocationStore) Nearby(
	ctx context.Context,
	latitude float64,
	longitude float64,
	radiusKm float64,
) ([]domain.DriverPoint, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	// GEO members do not support individual TTLs. Sweep the companion expiry
	// index before searching so expired payloads cannot consume result slots.
	if err := repository.cleanupExpiredDrivers(ctx); err != nil {
		repository.log().WarnContext(ctx, "clean up expired driver locations failed", "error", err)
	}

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
		return nil, fmt.Errorf("search nearby driver locations: %w", err)
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
		return nil, fmt.Errorf("load nearby driver locations: %w", err)
	}

	result := make([]domain.DriverPoint, 0, len(locationIDs))
	staleLocations := make([]string, 0, len(locationIDs))
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
		if err := jsonv2.Unmarshal([]byte(payload), &point); err != nil ||
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
		if _, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
			pipe.ZRem(ctx, driverLocationsKey, staleLocations)
			pipe.ZRem(ctx, driverLocationExpiryKey, staleLocations)
			return nil
		}); err != nil {
			repository.log().WarnContext(ctx, "remove stale driver locations failed", "error", err)
		}
	}
	return result, nil
}

func (repository *DriverLocationStore) cleanupExpiredDrivers(ctx context.Context) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if err := repository.client.Eval(
		ctx,
		cleanupExpiredDriversScript,
		[]string{driverLocationExpiryKey, driverLocationsKey},
		time.Now().UnixMilli(),
		locationCleanupBatchSize,
		driverLocationKeyPrefix,
	).Err(); err != nil {
		return fmt.Errorf("clean up expired driver locations: %w", err)
	}
	return nil
}

func (repository *DriverLocationStore) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	if err := repository.validate(); err != nil {
		return domain.DriverPoint{}, err
	}
	return repository.get(ctx, driverLocationKey(driverID))
}

func (repository *DriverLocationStore) UpsertPassenger(
	ctx context.Context,
	rideID string,
	point domain.DriverPoint,
) error {
	if err := repository.validate(); err != nil {
		return err
	}
	payload, err := jsonv2.Marshal(point)
	if err != nil {
		return fmt.Errorf("marshal passenger location: %w", err)
	}
	if err := repository.client.Set(
		ctx,
		"passenger:location:"+rideID,
		payload,
		passengerLocationTTL,
	).Err(); err != nil {
		return fmt.Errorf("persist passenger location: %w", err)
	}
	return nil
}

func (repository *DriverLocationStore) GetPassenger(ctx context.Context, rideID string) (domain.DriverPoint, error) {
	if err := repository.validate(); err != nil {
		return domain.DriverPoint{}, err
	}
	return repository.get(ctx, "passenger:location:"+rideID)
}

func (repository *DriverLocationStore) get(ctx context.Context, key string) (domain.DriverPoint, error) {
	payload, err := repository.client.Get(ctx, key).Bytes()
	if errors.Is(err, redis.Nil) {
		return domain.DriverPoint{}, domain.ErrLocationNotFound
	}
	if err != nil {
		return domain.DriverPoint{}, fmt.Errorf("read location: %w", err)
	}
	var point domain.DriverPoint
	if err := jsonv2.Unmarshal(payload, &point); err != nil {
		return domain.DriverPoint{}, fmt.Errorf("decode location: %w", err)
	}
	return point, nil
}

func (repository *DriverLocationStore) validate() error {
	if repository == nil || repository.client == nil {
		return errors.New("driver location store is not configured")
	}
	return nil
}

func driverLocationKey(driverID string) string {
	return driverLocationKeyPrefix + driverID
}
