package redis

import (
	"context"
	"encoding/json"
	"fmt"
	"location-service/internal/domain"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

type redisAdapter struct {
	client *redisclient.Client
}

const (
	geocodeCacheKeyPrefix = "geocode:mapbox:v2"
	nearbyCacheKeyPrefix  = "nearby:mapbox:v1"
	searchCacheKeyPrefix  = "search:mapbox:v1"
	routeCacheKeyPrefix   = "route:mapbox:v1"
)

func NewRedisAdapter(redisURL string) domain.CacheRepository {
	if redisURL == "" {
		return nil
	}
	opts, err := redisclient.ParseURL(redisURL)
	if err != nil {
		opts = &redisclient.Options{
			Addr: redisURL,
		}
	}
	client := redisclient.NewClient(opts)
	return &redisAdapter{client: client}
}

func (r *redisAdapter) GetGeocodeCache(ctx context.Context, lat, lng float64) (*domain.Place, error) {
	key := fmt.Sprintf("%s:%.4f:%.4f", geocodeCacheKeyPrefix, lat, lng)
	val, err := r.client.Get(ctx, key).Result()
	if err != nil {
		return nil, err
	}
	var place domain.Place
	if err := json.Unmarshal([]byte(val), &place); err != nil {
		return nil, err
	}
	return &place, nil
}

func (r *redisAdapter) SetGeocodeCache(ctx context.Context, lat, lng float64, place *domain.Place) error {
	key := fmt.Sprintf("%s:%.4f:%.4f", geocodeCacheKeyPrefix, lat, lng)
	data, err := json.Marshal(place)
	if err != nil {
		return err
	}
	return r.client.Set(ctx, key, data, 24*time.Hour).Err()
}

func (r *redisAdapter) GetNearbyCache(ctx context.Context, lat, lng float64, page int) ([]domain.Place, error) {
	key := fmt.Sprintf("%s:%.3f:%.3f:%d", nearbyCacheKeyPrefix, lat, lng, page)
	val, err := r.client.Get(ctx, key).Result()
	if err != nil {
		return nil, err
	}
	var places []domain.Place
	if err := json.Unmarshal([]byte(val), &places); err != nil {
		return nil, err
	}
	return places, nil
}

func (r *redisAdapter) SetNearbyCache(ctx context.Context, lat, lng float64, page int, places []domain.Place) error {
	key := fmt.Sprintf("%s:%.3f:%.3f:%d", nearbyCacheKeyPrefix, lat, lng, page)
	data, err := json.Marshal(places)
	if err != nil {
		return err
	}
	return r.client.Set(ctx, key, data, 1*time.Hour).Err()
}

func (r *redisAdapter) GetSearchCache(ctx context.Context, query string, lat, lng float64) ([]domain.Place, error) {
	key := fmt.Sprintf("%s:%s:%.3f:%.3f", searchCacheKeyPrefix, query, lat, lng)
	val, err := r.client.Get(ctx, key).Result()
	if err != nil {
		return nil, err
	}
	var places []domain.Place
	if err := json.Unmarshal([]byte(val), &places); err != nil {
		return nil, err
	}
	return places, nil
}

func (r *redisAdapter) SetSearchCache(ctx context.Context, query string, lat, lng float64, places []domain.Place) error {
	key := fmt.Sprintf("%s:%s:%.3f:%.3f", searchCacheKeyPrefix, query, lat, lng)
	data, err := json.Marshal(places)
	if err != nil {
		return err
	}
	return r.client.Set(ctx, key, data, 10*time.Minute).Err()
}

func (r *redisAdapter) GetRouteCache(ctx context.Context, originLat, originLng, destLat, destLng float64) (*domain.Route, error) {
	key := routeCacheKey(originLat, originLng, destLat, destLng)
	val, err := r.client.Get(ctx, key).Result()
	if err != nil {
		return nil, err
	}
	var route domain.Route
	if err := json.Unmarshal([]byte(val), &route); err != nil {
		return nil, err
	}
	return &route, nil
}

func (r *redisAdapter) SetRouteCache(ctx context.Context, route *domain.Route) error {
	key := routeCacheKey(route.OriginLat, route.OriginLng, route.DestLat, route.DestLng)
	data, err := json.Marshal(route)
	if err != nil {
		return err
	}
	return r.client.Set(ctx, key, data, 30*time.Minute).Err()
}

func routeCacheKey(originLat, originLng, destLat, destLng float64) string {
	return fmt.Sprintf(
		"%s:%.5f:%.5f:%.5f:%.5f",
		routeCacheKeyPrefix,
		originLat,
		originLng,
		destLat,
		destLng,
	)
}
