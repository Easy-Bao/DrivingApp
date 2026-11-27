package redis

import (
	"context"
	jsonv2 "encoding/json/v2"
	"errors"
	"fmt"
	"log/slog"
	"time"

	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/domain"
	redis "github.com/redis/go-redis/v9"
)

const (
	_driverLocationsKey             = "drivers:locations"
	_driverLocationExpiryKey        = "drivers:locations:expiry"
	_driverLocationKeyPrefix        = "driver:location:"
	_driverLocationObservedAtPrefix = "driver:location:observed-at:"
	_driverLocationTTL              = 45 * time.Second
	_locationCleanupBatchSize       = 100
	_locationCleanupMaxBatches      = 5
)

type driverLocationRecord struct {
	DriverID   string    `json:"driver_id"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Heading    float64   `json:"heading,omitempty"`
	Speed      float64   `json:"speed,omitempty"`
	ObservedAt time.Time `json:"observed_at"`
}

func newDriverLocationRecord(point domain.DriverPoint) driverLocationRecord {
	return driverLocationRecord{
		DriverID:   point.DriverID,
		Latitude:   point.Latitude,
		Longitude:  point.Longitude,
		Heading:    point.Heading,
		Speed:      point.Speed,
		ObservedAt: point.ObservedAt,
	}
}

func (record driverLocationRecord) point() domain.DriverPoint {
	return domain.DriverPoint{
		DriverID:   record.DriverID,
		Latitude:   record.Latitude,
		Longitude:  record.Longitude,
		Heading:    record.Heading,
		Speed:      record.Speed,
		ObservedAt: record.ObservedAt,
	}
}

var _cleanupExpiredDriversScript = redis.NewScript(`
local expired = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1], 'LIMIT', '0', ARGV[2])
for _, driver_id in ipairs(expired) do
  redis.call('ZREM', KEYS[1], driver_id)
  redis.call('ZREM', KEYS[2], driver_id)
  redis.call('DEL', ARGV[3] .. driver_id)
  redis.call('DEL', ARGV[4] .. driver_id)
end
return #expired
`)

var _upsertDriverLocationScript = redis.NewScript(`
local latest = redis.call('GET', KEYS[4])
if latest and tonumber(latest) >= tonumber(ARGV[7]) then
  return 0
end
redis.call('GEOADD', KEYS[1], ARGV[1], ARGV[2], ARGV[3])
redis.call('SET', KEYS[2], ARGV[4], 'PX', ARGV[5])
redis.call('ZADD', KEYS[3], ARGV[6], ARGV[3])
redis.call('SET', KEYS[4], ARGV[7], 'PX', ARGV[5])
return 1
`)

var _removeStaleDriverLocationsScript = redis.NewScript(`
local removed = 0
for i = 3, #ARGV, 2 do
  local driver_id = ARGV[i]
  local expected = ARGV[i + 1]
  local payload_key = ARGV[1] .. driver_id
  local current = redis.call('GET', payload_key)
  if ((not current or current == '') and expected == '') or
     (current and expected ~= '' and current == expected) then
    redis.call('ZREM', KEYS[1], driver_id)
    redis.call('ZREM', KEYS[2], driver_id)
    if current then
      redis.call('DEL', payload_key)
    end
    redis.call('DEL', ARGV[2] .. driver_id)
    removed = removed + 1
  end
end
return removed
`)

type DriverLocationStore struct {
	client *redis.Client
	logger *slog.Logger
	ttl    time.Duration
}

var _ locationapp.LocationStore = (*DriverLocationStore)(nil)

func NewDriverLocationStore(client *redis.Client) *DriverLocationStore {
	return &DriverLocationStore{
		client: client,
		logger: slog.Default(),
		ttl:    _driverLocationTTL,
	}
}

func (repository *DriverLocationStore) WithTTL(ttl time.Duration) *DriverLocationStore {
	if repository != nil && ttl > 0 {
		repository.ttl = ttl
	}
	return repository
}

func (repository *DriverLocationStore) WithLogger(logger *slog.Logger) *DriverLocationStore {
	if repository != nil && logger != nil {
		repository.logger = logger
	}
	return repository
}

func (repository *DriverLocationStore) locationTTL() time.Duration {
	if repository != nil && repository.ttl > 0 {
		return repository.ttl
	}
	return _driverLocationTTL
}

func (repository *DriverLocationStore) computeRemainingTTL(
	observedAt time.Time,
	now time.Time,
) (time.Duration, time.Time, bool) {
	ttl := repository.locationTTL()
	nowUTC := now.UTC()
	observedUTC := observedAt.UTC()
	if observedUTC.IsZero() {
		observedUTC = nowUTC
	}
	expiresAt := observedUTC.Add(ttl)
	remaining := expiresAt.Sub(nowUTC)
	if remaining <= 0 {
		return 0, time.Time{}, false
	}
	if remaining > ttl {
		remaining = ttl
		expiresAt = nowUTC.Add(ttl)
	}
	if remaining.Milliseconds() <= 0 {
		return 0, time.Time{}, false
	}
	return remaining, expiresAt, true
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
	now := time.Now().UTC()
	if point.ObservedAt.IsZero() {
		point.ObservedAt = now
	} else {
		point.ObservedAt = point.ObservedAt.UTC()
	}
	remainingTTL, expiresAt, fresh := repository.computeRemainingTTL(point.ObservedAt, now)
	if !fresh {
		return domain.ErrStaleLocation
	}
	payload, err := jsonv2.Marshal(newDriverLocationRecord(point))
	if err != nil {
		return fmt.Errorf("marshal driver location: %w", err)
	}
	result, err := _upsertDriverLocationScript.Run(
		ctx,
		repository.client,
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
		remainingTTL.Milliseconds(),
		expiresAt.UnixMilli(),
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

type nearbyLookupTimings struct {
	ctx                  context.Context
	logger               *slog.Logger
	enabled              bool
	totalStartedAt       time.Time
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
	outcome              string
}

func newNearbyLookupTimings(ctx context.Context, logger *slog.Logger) *nearbyLookupTimings {
	timings := &nearbyLookupTimings{
		ctx:     ctx,
		logger:  logger,
		enabled: ctx != nil && logger.Enabled(ctx, slog.LevelDebug),
		outcome: "failed",
	}
	timings.totalStartedAt = timings.start()
	return timings
}

func (timings *nearbyLookupTimings) start() time.Time {
	if !timings.enabled {
		return time.Time{}
	}
	return time.Now()
}

func (timings *nearbyLookupTimings) measure(startedAt time.Time) time.Duration {
	if startedAt.IsZero() {
		return 0
	}
	return time.Since(startedAt)
}

func (timings *nearbyLookupTimings) log() {
	if !timings.enabled {
		return
	}
	timings.logger.LogAttrs(timings.ctx, slog.LevelDebug, "nearby driver lookup stage timings",
		slog.String("outcome", timings.outcome),
		slog.Int64("total_us", timings.measure(timings.totalStartedAt).Microseconds()),
		slog.Int64("expiry_cleanup_us", timings.cleanupDuration.Microseconds()),
		slog.Int64("geo_search_us", timings.geoSearchDuration.Microseconds()),
		slog.Int64("payload_fetch_us", timings.payloadFetchDuration.Microseconds()),
		slog.Int64("decode_us", timings.decodeDuration.Microseconds()),
		slog.Int64("stale_member_cleanup_us", timings.staleCleanupDuration.Microseconds()),
		slog.Int("expired_count", timings.expiredCount),
		slog.Int("candidate_count", timings.candidateCount),
		slog.Int("valid_count", timings.validCount),
		slog.Int("stale_count", timings.staleCount),
		slog.Bool("expiry_cleanup_succeeded", timings.cleanupSucceeded),
	)
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
	timings := newNearbyLookupTimings(ctx, logger)
	defer timings.log()

	// GEO members do not support individual TTLs. Sweep the companion expiry
	// index before searching so expired payloads cannot consume result slots.
	cleanupStartedAt := timings.start()
	var cleanupErr error
	timings.expiredCount, cleanupErr = repository.cleanupExpiredDriversBounded(ctx)
	timings.cleanupDuration = timings.measure(cleanupStartedAt)
	timings.cleanupSucceeded = cleanupErr == nil
	if cleanupErr != nil {
		logger.WarnContext(ctx, "clean up expired driver locations failed", "error", cleanupErr)
	}

	// Only the member IDs are needed here. GeoSearchLocation expects a nested
	// location response when using RESP3, but Redis returns a flat member list
	// when coordinates are not requested. GeoSearch matches that response shape
	// and keeps this lookup compatible with the native Redis/Valkey setup.
	geoSearchStartedAt := timings.start()
	locationIDs, err := repository.client.GeoSearch(ctx, _driverLocationsKey, &redis.GeoSearchQuery{
		Longitude:  longitude,
		Latitude:   latitude,
		Radius:     radiusKm,
		RadiusUnit: "km",
		Sort:       "ASC",
		Count:      20,
	}).Result()
	timings.geoSearchDuration = timings.measure(geoSearchStartedAt)
	if err != nil {
		return nil, fmt.Errorf("search nearby driver locations: %w", err)
	}
	timings.candidateCount = len(locationIDs)
	if len(locationIDs) == 0 {
		timings.outcome = "no_candidates"
		return []domain.DriverPoint{}, nil
	}

	keys := make([]string, 0, len(locationIDs))
	for _, locationID := range locationIDs {
		keys = append(keys, driverLocationKey(locationID))
	}
	payloadFetchStartedAt := timings.start()
	payloads, err := repository.client.MGet(ctx, keys...).Result()
	timings.payloadFetchDuration = timings.measure(payloadFetchStartedAt)
	if err != nil {
		return nil, fmt.Errorf("load nearby driver locations: %w", err)
	}

	type staleLocationCandidate struct {
		driverID        string
		expectedPayload string
	}
	result := make([]domain.DriverPoint, 0, len(locationIDs))
	staleLocations := make([]staleLocationCandidate, 0, len(locationIDs))
	decodeStartedAt := timings.start()
	for index, locationID := range locationIDs {
		if index >= len(payloads) {
			staleLocations = append(staleLocations, staleLocationCandidate{driverID: locationID})
			continue
		}
		rawPayload := payloads[index]
		payload, ok := rawPayload.(string)
		if !ok {
			staleLocations = append(staleLocations, staleLocationCandidate{driverID: locationID})
			continue
		}
		var record driverLocationRecord
		if err := jsonv2.Unmarshal([]byte(payload), &record); err != nil ||
			record.DriverID == "" ||
			record.DriverID != locationID {
			staleLocations = append(staleLocations, staleLocationCandidate{
				driverID:        locationID,
				expectedPayload: payload,
			})
			continue
		}
		point := record.point()
		result = append(result, point)
	}
	timings.decodeDuration = timings.measure(decodeStartedAt)
	timings.validCount = len(result)
	timings.staleCount = len(staleLocations)
	if len(staleLocations) > 0 {
		// Expired or corrupt payloads leave geo members behind; guard removals
		// against concurrent refreshes in Lua so a fresh write is never wiped.
		staleCleanupStartedAt := timings.start()
		args := make([]any, 0, 2+len(staleLocations)*2)
		args = append(args, _driverLocationKeyPrefix, _driverLocationObservedAtPrefix)
		for _, candidate := range staleLocations {
			args = append(args, candidate.driverID, candidate.expectedPayload)
		}
		if _, err := _removeStaleDriverLocationsScript.Run(
			ctx,
			repository.client,
			[]string{_driverLocationsKey, _driverLocationExpiryKey},
			args...,
		).Int(); err != nil {
			repository.log().WarnContext(ctx, "remove stale driver locations failed", "error", err)
			timings.outcome = "stale_cleanup_failed"
		} else {
			timings.outcome = "stale_candidates_removed"
		}
		timings.staleCleanupDuration = timings.measure(staleCleanupStartedAt)
	} else {
		timings.outcome = "success"
	}
	return result, nil
}

func (repository *DriverLocationStore) cleanupExpiredDriversBounded(ctx context.Context) (int, error) {
	totalExpired := 0
	for range _locationCleanupMaxBatches {
		expiredCount, err := repository.cleanupExpiredDrivers(ctx)
		totalExpired += expiredCount
		if err != nil {
			return totalExpired, err
		}
		if expiredCount < _locationCleanupBatchSize {
			break
		}
	}
	return totalExpired, nil
}

func (repository *DriverLocationStore) cleanupExpiredDrivers(ctx context.Context) (int, error) {
	if err := repository.validate(); err != nil {
		return 0, err
	}
	expiredCount, err := _cleanupExpiredDriversScript.Run(
		ctx,
		repository.client,
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
	payload, err := jsonv2.Marshal(newDriverLocationRecord(point))
	if err != nil {
		return fmt.Errorf("marshal passenger location: %w", err)
	}
	if err := repository.client.Set(
		ctx,
		"passenger:location:"+rideID,
		payload,
		repository.locationTTL(),
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
	var record driverLocationRecord
	if err := jsonv2.Unmarshal(payload, &record); err != nil {
		return domain.DriverPoint{}, fmt.Errorf("decode location: %w", err)
	}
	return record.point(), nil
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
