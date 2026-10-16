package redis

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	locationports "github.com/Easy-Bao/DrivingApp/server/internal/location/app"
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

type Cache struct {
	client *redisclient.Client
	ttl    time.Duration
}

var _ locationports.Cache = (*Cache)(nil)

func NewCache(client *redisclient.Client) *Cache {
	return &Cache{client: client, ttl: time.Hour}
}

func (cache *Cache) GetPlaces(ctx context.Context, key string) ([]domain.Place, error) {
	var records []placeCacheRecord
	if err := cache.get(ctx, key, &records); err != nil {
		return nil, err
	}
	if records == nil {
		return nil, nil
	}
	places := make([]domain.Place, 0, len(records))
	for _, record := range records {
		places = append(places, record.place())
	}
	return places, nil
}

func (cache *Cache) SetPlaces(ctx context.Context, key string, places []domain.Place) error {
	if places == nil {
		return cache.set(ctx, key, []placeCacheRecord(nil))
	}
	records := make([]placeCacheRecord, 0, len(places))
	for _, place := range places {
		records = append(records, newPlaceCacheRecord(place))
	}
	return cache.set(ctx, key, records)
}

func (cache *Cache) GetPlace(ctx context.Context, key string) (*domain.Place, error) {
	var record placeCacheRecord
	if err := cache.get(ctx, key, &record); err != nil {
		return nil, err
	}
	place := record.place()
	return &place, nil
}

func (cache *Cache) SetPlace(ctx context.Context, key string, place *domain.Place) error {
	if place == nil {
		return cache.set(ctx, key, (*placeCacheRecord)(nil))
	}
	record := newPlaceCacheRecord(*place)
	return cache.set(ctx, key, record)
}

func (cache *Cache) GetMatrix(ctx context.Context, key string) (*domain.Matrix, error) {
	var record matrixCacheRecord
	if err := cache.get(ctx, key, &record); err != nil {
		return nil, err
	}
	return record.matrix(), nil
}

func (cache *Cache) SetMatrix(ctx context.Context, key string, matrix *domain.Matrix) error {
	return cache.set(ctx, key, newMatrixCacheRecord(matrix))
}

func (cache *Cache) get(ctx context.Context, key string, target any) error {
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

func (cache *Cache) set(ctx context.Context, key string, value any) error {
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
