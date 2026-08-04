package usecase

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

var ErrEmptySearch = errors.New("location search query is empty")

type Service struct {
	provider  domain.Provider
	cache     domain.Cache
	publisher domain.EventPublisher
}

func NewService(provider domain.Provider) *Service {
	return NewServiceWithInfrastructure(provider, nil, nil)
}

func NewServiceWithInfrastructure(provider domain.Provider, cache domain.Cache, publisher domain.EventPublisher) *Service {
	return &Service{provider: provider, cache: cache, publisher: publisher}
}

func (service *Service) Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return nil, ErrEmptySearch
	}
	key := fmt.Sprintf("search:%s:%.4f:%.4f", query, origin.Latitude, origin.Longitude)
	var places []domain.Place
	if service.cache != nil && service.cache.Get(ctx, key, &places) == nil {
		return places, nil
	}
	places, err := service.provider.Search(ctx, query, origin)
	if err == nil && service.cache != nil {
		_ = service.cache.Set(ctx, key, places)
	}
	return places, err
}

func (service *Service) Nearby(ctx context.Context, origin domain.Coordinates, page int) ([]domain.Place, error) {
	if page < 1 {
		page = 1
	}
	key := fmt.Sprintf("nearby:%.4f:%.4f:%d", origin.Latitude, origin.Longitude, page)
	var places []domain.Place
	if service.cache != nil && service.cache.Get(ctx, key, &places) == nil {
		return places, nil
	}
	places, err := service.provider.Nearby(ctx, origin, page)
	if err == nil && service.cache != nil {
		_ = service.cache.Set(ctx, key, places)
	}
	return places, err
}

func (service *Service) ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error) {
	key := fmt.Sprintf("reverse:%.4f:%.4f", coordinates.Latitude, coordinates.Longitude)
	var place domain.Place
	if service.cache != nil && service.cache.Get(ctx, key, &place) == nil {
		return &place, nil
	}
	result, err := service.provider.ReverseGeocode(ctx, coordinates)
	if err != nil {
		return nil, err
	}
	if service.cache != nil && result != nil {
		_ = service.cache.Set(ctx, key, result)
	}
	if service.publisher != nil && result != nil {
		_ = service.publisher.Publish(ctx, domain.LocationEvent{Type: "LOCATION_RESOLVED", Place: result, Latitude: coordinates.Latitude, Longitude: coordinates.Longitude})
	}
	return result, nil
}

func (service *Service) Route(ctx context.Context, origin, destination domain.Coordinates) (*domain.Route, error) {
	return service.provider.Route(ctx, origin, destination)
}
