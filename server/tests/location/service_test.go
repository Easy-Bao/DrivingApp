package location_test

import (
	"context"
	"errors"
	"strings"
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

func (providerStub) Matrix(context.Context, domain.Coordinates, []domain.Coordinates) (*domain.Matrix, error) {
	return &domain.Matrix{DistancesKm: []float64{1}, DurationsMin: []float64{2}}, nil
}

type routeProviderSpy struct {
	providerStub
	options domain.RouteOptions
	calls   int
}

func (provider *routeProviderSpy) Route(_ context.Context, _, _ domain.Coordinates, options domain.RouteOptions) (*domain.Route, error) {
	provider.calls++
	provider.options = options
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
	service := usecase.NewServiceWithCache(providerStub{}, cache)
	places, err := service.Nearby(context.Background(), domain.Coordinates{Latitude: 7.8, Longitude: 123.4}, 1)
	if err != nil || len(places) != 1 || places[0].Name != "Nearby Place" {
		t.Fatalf("nearby places = %#v, %v", places, err)
	}
	places, err = service.Nearby(context.Background(), domain.Coordinates{Latitude: 7.8, Longitude: 123.4}, 1)
	if err != nil || len(places) != 1 {
		t.Fatalf("cached nearby places = %#v, %v", places, err)
	}
}

func TestServiceRejectsUnboundedSearchAndInvalidRouteCoordinates(t *testing.T) {
	service := usecase.NewService(providerStub{})
	if _, err := service.Search(context.Background(), strings.Repeat("x", 257), domain.Coordinates{}); err != usecase.ErrSearchTooLong {
		t.Fatalf("long search error = %v, want %v", err, usecase.ErrSearchTooLong)
	}
	if _, err := service.Route(
		context.Background(),
		domain.Coordinates{Latitude: 91, Longitude: 123},
		domain.Coordinates{Latitude: 7, Longitude: 123},
		domain.RouteOptions{},
	); err != usecase.ErrInvalidCoordinates {
		t.Fatalf("invalid route error = %v, want %v", err, usecase.ErrInvalidCoordinates)
	}
}

func TestServiceOwnsRouteOptionValidationAndNormalization(t *testing.T) {
	provider := &routeProviderSpy{}
	service := usecase.NewService(provider)
	origin := domain.Coordinates{Latitude: 7.8, Longitude: 123.4}
	destination := domain.Coordinates{Latitude: 7.9, Longitude: 123.5}

	if _, err := service.Route(context.Background(), origin, destination, domain.RouteOptions{}); err != nil {
		t.Fatalf("route failed: %v", err)
	}
	if provider.options.Preference != domain.RoutePreferenceFastest || provider.options.Profile != domain.RouteProfileDriving {
		t.Fatalf("provider received unnormalized options: %#v", provider.options)
	}

	_, err := service.Route(context.Background(), origin, destination, domain.RouteOptions{Profile: "walking"})
	if !errors.Is(err, usecase.ErrInvalidRouteOptions) {
		t.Fatalf("invalid options error = %v, want %v", err, usecase.ErrInvalidRouteOptions)
	}
	if provider.calls != 1 {
		t.Fatalf("provider calls = %d, want 1", provider.calls)
	}
}
