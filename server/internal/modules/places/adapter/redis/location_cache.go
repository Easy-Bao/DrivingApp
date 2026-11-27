package redis

import (
	"context"
	"errors"
	"time"

	locationports "github.com/Easy-Bao/DrivingApp/server/internal/modules/places/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
	platformcache "github.com/Easy-Bao/DrivingApp/server/internal/platform/cache"
	redisclient "github.com/redis/go-redis/v9"
)

type placeCacheRecord struct {
	ID             string            `json:"id"`
	Name           string            `json:"name"`
	Address        string            `json:"address"`
	Category       string            `json:"category"`
	Latitude       float64           `json:"lat"`
	Longitude      float64           `json:"lng"`
	DistanceKm     float64           `json:"distance_km,omitempty"`
	MatchType      string            `json:"match_type,omitempty"`
	DistanceMeters float64           `json:"distance_meters,omitempty"`
	Confidence     float64           `json:"confidence,omitempty"`
	Context        map[string]string `json:"context,omitempty"`
}

func newPlaceCacheRecord(place domain.Place) placeCacheRecord {
	return placeCacheRecord{
		ID:             place.ID,
		Name:           place.Name,
		Address:        place.Address,
		Category:       place.Category,
		Latitude:       place.Latitude,
		Longitude:      place.Longitude,
		DistanceKm:     place.DistanceKm,
		MatchType:      place.MatchType,
		DistanceMeters: place.DistanceMeters,
		Confidence:     place.Confidence,
		Context:        place.Context,
	}
}

func (record placeCacheRecord) place() domain.Place {
	return domain.Place{
		ID:             record.ID,
		Name:           record.Name,
		Address:        record.Address,
		Category:       record.Category,
		Latitude:       record.Latitude,
		Longitude:      record.Longitude,
		DistanceKm:     record.DistanceKm,
		MatchType:      record.MatchType,
		DistanceMeters: record.DistanceMeters,
		Confidence:     record.Confidence,
		Context:        record.Context,
	}
}

type matrixCacheRecord struct {
	DistancesKm  []float64 `json:"distances_km"`
	DurationsMin []float64 `json:"durations_min"`
}

func newMatrixCacheRecord(matrix *domain.Matrix) *matrixCacheRecord {
	if matrix == nil {
		return nil
	}
	return &matrixCacheRecord{DistancesKm: matrix.DistancesKm, DurationsMin: matrix.DurationsMin}
}

func (record matrixCacheRecord) matrix() *domain.Matrix {
	return &domain.Matrix{DistancesKm: record.DistancesKm, DurationsMin: record.DurationsMin}
}

const (
	_defaultPlaceCacheTTL  = time.Hour
	_defaultMatrixCacheTTL = 5 * time.Minute
)

type Cache struct {
	client    *redisclient.Client
	ttl       time.Duration
	matrixTTL time.Duration
}

var _ locationports.Cache = (*Cache)(nil)

func NewCache(client *redisclient.Client) *Cache {
	return &Cache{
		client:    client,
		ttl:       _defaultPlaceCacheTTL,
		matrixTTL: _defaultMatrixCacheTTL,
	}
}

func (cache *Cache) GetPlaces(ctx context.Context, key string) ([]domain.Place, error) {
	records, err := getLocationCache[[]placeCacheRecord](ctx, cache, key)
	if err != nil {
		return nil, err
	}
	if records == nil {
		return nil, locationports.ErrCacheMiss
	}
	places := make([]domain.Place, 0, len(records))
	for _, record := range records {
		places = append(places, record.place())
	}
	return places, nil
}

func (cache *Cache) SetPlaces(ctx context.Context, key string, places []domain.Place) error {
	if places == nil {
		return cache.set(ctx, key, []placeCacheRecord{}, cache.ttl)
	}
	records := make([]placeCacheRecord, 0, len(places))
	for _, place := range places {
		records = append(records, newPlaceCacheRecord(place))
	}
	return cache.set(ctx, key, records, cache.ttl)
}

func (cache *Cache) GetPlace(ctx context.Context, key string) (*domain.Place, error) {
	record, err := getLocationCache[*placeCacheRecord](ctx, cache, key)
	if err != nil {
		return nil, err
	}
	if record == nil {
		return nil, locationports.ErrCacheMiss
	}
	place := record.place()
	return &place, nil
}

func (cache *Cache) SetPlace(ctx context.Context, key string, place *domain.Place) error {
	if place == nil {
		return nil
	}
	record := newPlaceCacheRecord(*place)
	return cache.set(ctx, key, record, cache.ttl)
}

func (cache *Cache) GetMatrix(ctx context.Context, key string) (*domain.Matrix, error) {
	record, err := getLocationCache[*matrixCacheRecord](ctx, cache, key)
	if err != nil {
		return nil, err
	}
	if record == nil {
		return nil, locationports.ErrCacheMiss
	}
	return record.matrix(), nil
}

func (cache *Cache) SetMatrix(ctx context.Context, key string, matrix *domain.Matrix) error {
	if matrix == nil {
		return nil
	}
	ttl := cache.matrixTTL
	if ttl <= 0 {
		ttl = _defaultMatrixCacheTTL
	}
	return cache.set(ctx, key, newMatrixCacheRecord(matrix), ttl)
}

func getLocationCache[T any](ctx context.Context, cache *Cache, key string) (T, error) {
	var zero T
	if cache == nil || cache.client == nil {
		return zero, errors.New("location cache is not configured")
	}
	value, err := platformcache.GetJSON[T](ctx, cache.client, "location:"+key)
	if errors.Is(err, platformcache.ErrCacheMiss) {
		return zero, locationports.ErrCacheMiss
	}
	if err != nil {
		return zero, err
	}
	return value, nil
}

func (cache *Cache) set(ctx context.Context, key string, value any, ttl time.Duration) error {
	if cache == nil || cache.client == nil {
		return errors.New("location cache is not configured")
	}
	return platformcache.SetJSON(ctx, cache.client, "location:"+key, value, ttl)
}
