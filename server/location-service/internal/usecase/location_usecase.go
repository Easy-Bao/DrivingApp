package usecase

import (
	"context"
	"fmt"
	"location-service/internal/domain"
	"math"
	"time"
)

type LocationUseCase interface {
	ReverseGeocode(ctx context.Context, lat, lng float64) (*domain.Place, error)
	SearchPlaces(ctx context.Context, query string, lat, lng float64) ([]domain.Place, error)
	GetNearbyPois(ctx context.Context, lat, lng float64, page int) ([]domain.Place, error)
	GetRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*domain.Route, error)
}

type locationUseCase struct {
	repo  domain.LocationRepository
	cache domain.CacheRepository
	queue domain.QueuePublisher
}

func NewLocationUseCase(
	repo domain.LocationRepository,
	cache domain.CacheRepository,
	queue domain.QueuePublisher,
) LocationUseCase {
	return &locationUseCase{
		repo:  repo,
		cache: cache,
		queue: queue,
	}
}

func (uc *locationUseCase) ReverseGeocode(ctx context.Context, lat, lng float64) (*domain.Place, error) {
	if uc.cache != nil {
		if cached, err := uc.cache.GetGeocodeCache(ctx, lat, lng); err == nil && cached != nil {
			return cached, nil
		}
	}

	place, err := uc.repo.ReverseGeocode(ctx, lat, lng)
	if err != nil {
		return nil, err
	}

	if uc.cache != nil && place != nil {
		_ = uc.cache.SetGeocodeCache(ctx, lat, lng, place)
	}

	if uc.queue != nil && place != nil {
		_ = uc.queue.PublishLocationEvent(ctx, &domain.LocationUpdateEvent{
			ID:        fmt.Sprintf("loc-%d", time.Now().UnixNano()),
			DriverID:  "system",
			Latitude:  lat,
			Longitude: lng,
			Timestamp: time.Now(),
		})
	}

	return place, nil
}

func (uc *locationUseCase) SearchPlaces(ctx context.Context, query string, lat, lng float64) ([]domain.Place, error) {
	return uc.repo.SearchPlaces(ctx, query, lat, lng)
}

func (uc *locationUseCase) GetNearbyPois(ctx context.Context, lat, lng float64, page int) ([]domain.Place, error) {
	if uc.cache != nil {
		if cached, err := uc.cache.GetNearbyCache(ctx, lat, lng, page); err == nil && len(cached) > 0 {
			return cached, nil
		}
	}

	places, err := uc.repo.GetNearbyPois(ctx, lat, lng, page)
	if err != nil {
		return nil, err
	}

	if uc.cache != nil && len(places) > 0 {
		_ = uc.cache.SetNearbyCache(ctx, lat, lng, page, places)
	}

	return places, nil
}

func (uc *locationUseCase) GetRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*domain.Route, error) {
	return uc.repo.GetRoute(ctx, originLat, originLng, destLat, destLng)
}

func CalculateHaversine(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadiusKm = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLng := (lng2 - lng1) * math.Pi / 180.0

	a := math.Sin(dLat/2.0)*math.Sin(dLat/2.0) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLng/2.0)*math.Sin(dLng/2.0)
	c := 2.0 * math.Asin(math.Sqrt(a))

	return earthRadiusKm * c
}
