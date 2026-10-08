package tracking

import (
	"context"
	jsonv2 "encoding/json/v2"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
	redis "github.com/redis/go-redis/v9"
)

const (
	_driverLocationsKey             = "drivers:locations"
	_driverLocationExpiryKey        = "drivers:locations:expiry"
	_driverLocationKeyPrefix        = "driver:location:"
	_driverLocationObservedAtPrefix = "driver:location:observed-at:"
	_driverLocationTTL              = 45 * time.Second
	_passengerLocationTTL           = 45 * time.Second
	_locationCleanupBatchSize       = 100
)

const _cleanupExpiredDriversScript = `
local expired = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1], 'LIMIT', '0', ARGV[2])
for _, driver_id in ipairs(expired) do
  redis.call('ZREM', KEYS[1], driver_id)
  redis.call('ZREM', KEYS[2], driver_id)
  redis.call('DEL', ARGV[3] .. driver_id)
  redis.call('DEL', ARGV[4] .. driver_id)
end
return #expired
`

const _upsertDriverLocationScript = `
local latest = redis.call('GET', KEYS[4])
if latest and tonumber(latest) >= tonumber(ARGV[7]) then
  return 0
end
redis.call('GEOADD', KEYS[1], ARGV[1], ARGV[2], ARGV[3])
redis.call('SET', KEYS[2], ARGV[4], 'PX', ARGV[5])
redis.call('ZADD', KEYS[3], ARGV[6], ARGV[3])
redis.call('SET', KEYS[4], ARGV[7], 'PX', ARGV[5])
return 1
`

type DriverLocationStore struct {
	client *redis.Client
	logger *slog.Logger
}

var _ LocationStore = (*DriverLocationStore)(nil)

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
	expiresAt := time.Now().Add(_driverLocationTTL).UnixMilli()
	result, err := repository.client.Eval(
		ctx,
		_upsertDriverLocationScript,
		[]string{
			_driverLocationsKey,
			driverLocationKey(point.DriverID),
			_driverLocationExpiryKey,
			driverLocationObservedAtKey(point.DriverID),
		},
		point.Longitude,
		point.Latitude,
		point.DriverID,
		payload,
		_driverLocationTTL.Milliseconds(),
		expiresAt,
		point.ObservedAt.UnixMilli(),
	).Int()
	if err != nil {
		return fmt.Errorf("persist driver location script: %w", err)
	}
	if result == 0 {
		return domain.ErrStaleLocation
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
		pipe.ZRem(ctx, _driverLocationsKey, driverID)
		pipe.ZRem(ctx, _driverLocationExpiryKey, driverID)
		pipe.Del(ctx, driverLocationKey(driverID))
		pipe.Del(ctx, driverLocationObservedAtKey(driverID))
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
	logger := repository.log()
	timingsEnabled := ctx != nil && logger.Enabled(ctx, slog.LevelDebug)
	startTiming := func() time.Time {
		if !timingsEnabled {
			return time.Time{}
		}
		return time.Now()
	}
	measure := func(startedAt time.Time) time.Duration {
		if startedAt.IsZero() {
			return 0
		}
		return time.Since(startedAt)
	}
	totalStartedAt := startTiming()
	var (
		cleanupDuration      time.Duration
		geoSearchDuration    time.Duration
		payloadFetchDuration time.Duration
		decodeDuration       time.Duration
		staleCleanupDuration time.Duration
		expiredCount         int
		candidateCount       int
		validCount           int
		staleCount           int
		cleanupSucceeded     bool
		outcome              = "failed"
	)
	defer func() {
		if !timingsEnabled {
			return
		}
		logger.LogAttrs(ctx, slog.LevelDebug, "nearby driver lookup stage timings",
			slog.String("outcome", outcome),
			slog.Int64("total_us", measure(totalStartedAt).Microseconds()),
			slog.Int64("expiry_cleanup_us", cleanupDuration.Microseconds()),
			slog.Int64("geo_search_us", geoSearchDuration.Microseconds()),
			slog.Int64("payload_fetch_us", payloadFetchDuration.Microseconds()),
			slog.Int64("decode_us", decodeDuration.Microseconds()),
			slog.Int64("stale_member_cleanup_us", staleCleanupDuration.Microseconds()),
			slog.Int("expired_count", expiredCount),
			slog.Int("candidate_count", candidateCount),
			slog.Int("valid_count", validCount),
			slog.Int("stale_count", staleCount),
			slog.Bool("expiry_cleanup_succeeded", cleanupSucceeded),
		)
	}()

	// GEO members do not support individual TTLs. Sweep the companion expiry
	// index before searching so expired payloads cannot consume result slots.
	cleanupStartedAt := startTiming()
	var cleanupErr error
	expiredCount, cleanupErr = repository.cleanupExpiredDrivers(ctx)
	cleanupDuration = measure(cleanupStartedAt)
	cleanupSucceeded = cleanupErr == nil
	if cleanupErr != nil {
		logger.WarnContext(ctx, "clean up expired driver locations failed", "error", cleanupErr)
	}

	// Only the member IDs are needed here. GeoSearchLocation expects a nested
	// location response when using RESP3, but Redis returns a flat member list
	// when coordinates are not requested. GeoSearch matches that response shape
	// and keeps this lookup compatible with the native Redis/Valkey setup.
	geoSearchStartedAt := startTiming()
	locationIDs, err := repository.client.GeoSearch(ctx, _driverLocationsKey, &redis.GeoSearchQuery{
		Longitude:  longitude,
		Latitude:   latitude,
		Radius:     radiusKm,
		RadiusUnit: "km",
		Sort:       "ASC",
		Count:      20,
	}).Result()
	geoSearchDuration = measure(geoSearchStartedAt)
	if err != nil {
		return nil, fmt.Errorf("search nearby driver locations: %w", err)
	}
	candidateCount = len(locationIDs)
	if len(locationIDs) == 0 {
		outcome = "no_candidates"
		return []domain.DriverPoint{}, nil
	}

	keys := make([]string, 0, len(locationIDs))
	for _, locationID := range locationIDs {
		keys = append(keys, driverLocationKey(locationID))
	}
	payloadFetchStartedAt := startTiming()
	payloads, err := repository.client.MGet(ctx, keys...).Result()
	payloadFetchDuration = measure(payloadFetchStartedAt)
	if err != nil {
		return nil, fmt.Errorf("load nearby driver locations: %w", err)
	}

	result := make([]domain.DriverPoint, 0, len(locationIDs))
	staleLocations := make([]string, 0, len(locationIDs))
	decodeStartedAt := startTiming()
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
	decodeDuration = measure(decodeStartedAt)
	validCount = len(result)
	staleCount = len(staleLocations)
	if len(staleLocations) > 0 {
		// Expired payloads leave geo members behind; cleanup is best effort so a
		// transient Redis write failure does not hide valid nearby drivers.
		staleCleanupStartedAt := startTiming()
		if _, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
			pipe.ZRem(ctx, _driverLocationsKey, staleLocations)
			pipe.ZRem(ctx, _driverLocationExpiryKey, staleLocations)
			return nil
		}); err != nil {
			repository.log().WarnContext(ctx, "remove stale driver locations failed", "error", err)
			outcome = "stale_cleanup_failed"
		} else {
			outcome = "stale_candidates_removed"
		}
		staleCleanupDuration = measure(staleCleanupStartedAt)
	} else {
		outcome = "success"
	}
	return result, nil
}

func (repository *DriverLocationStore) cleanupExpiredDrivers(ctx context.Context) (int, error) {
	if err := repository.validate(); err != nil {
		return 0, err
	}
	expiredCount, err := repository.client.Eval(
		ctx,
		_cleanupExpiredDriversScript,
		[]string{_driverLocationExpiryKey, _driverLocationsKey},
		time.Now().UnixMilli(),
		_locationCleanupBatchSize,
		_driverLocationKeyPrefix,
		_driverLocationObservedAtPrefix,
	).Int()
	if err != nil {
		return 0, fmt.Errorf("clean up expired driver locations: %w", err)
	}
	return expiredCount, nil
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
		_passengerLocationTTL,
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
	return _driverLocationKeyPrefix + driverID
}

func driverLocationObservedAtKey(driverID string) string {
	return _driverLocationObservedAtPrefix + driverID
}
