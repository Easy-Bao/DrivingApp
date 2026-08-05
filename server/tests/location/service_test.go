package location_test

import (
	"context"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
)

type providerStub struct{}

func (providerStub) Search(context.Context, string, domain.Coordinates) ([]domain.Place, error) {
	return []domain.Place{{Name: "Pagadian City"}}, nil
}
func (providerStub) Nearby(context.Context, domain.Coordinates, int) ([]domain.Place, error) {
	return []domain.Place{{Name: "Nearby Place"}}, nil
}

type cacheStub struct{ values map[string]any }

func (cache *cacheStub) Get(_ context.Context, key string, target any) error {
	value, ok := cache.values[key]
	if !ok {
		return context.Canceled
	}
	if places, ok := target.(*[]domain.Place); ok {
		*places = value.([]domain.Place)
		return nil
	}
	if place, ok := target.(*domain.Place); ok {
		*place = *value.(*domain.Place)
		return nil
	}
	return context.Canceled
}

func (cache *cacheStub) Set(_ context.Context, key string, value any) error {
	cache.values[key] = value
	return nil
}

func (providerStub) ReverseGeocode(context.Context, domain.Coordinates) (*domain.Place, error) {
	return &domain.Place{Name: "Pagadian City"}, nil
}

func (providerStub) Route(context.Context, domain.Coordinates, domain.Coordinates, domain.RouteOptions) (*domain.Route, error) {
	return &domain.Route{DistanceKm: 1}, nil
}

func TestServiceRejectsEmptySearch(t *testing.T) {
	service := usecase.NewService(providerStub{})
	_, err := service.Search(context.Background(), "  ", domain.Coordinates{})
	if err != usecase.ErrEmptySearch {
		t.Fatalf("expected ErrEmptySearch, got %v", err)
	}
}

func TestServiceDelegatesSearch(t *testing.T) {
	service := usecase.NewService(providerStub{})
	places, err := service.Search(context.Background(), "Pagadian", domain.Coordinates{})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(places) != 1 || places[0].Name != "Pagadian City" {
		t.Fatalf("unexpected places: %#v", places)
	}
}

func TestServiceSupportsNearbyPlacesAndCaching(t *testing.T) {
	cache := &cacheStub{values: map[string]any{}}
	service := usecase.NewServiceWithInfrastructure(providerStub{}, cache, nil)
	places, err := service.Nearby(context.Background(), domain.Coordinates{Latitude: 7.8, Longitude: 123.4}, 1)
	if err != nil || len(places) != 1 || places[0].Name != "Nearby Place" {
		t.Fatalf("nearby places = %#v, %v", places, err)
	}
	places, err = service.Nearby(context.Background(), domain.Coordinates{Latitude: 7.8, Longitude: 123.4}, 1)
	if err != nil || len(places) != 1 {
		t.Fatalf("cached nearby places = %#v, %v", places, err)
	}
}
