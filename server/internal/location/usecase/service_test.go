package usecase

import (
	"context"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

type providerStub struct{}

func (providerStub) Search(context.Context, string, domain.Coordinates) ([]domain.Place, error) {
	return []domain.Place{{Name: "Pagadian City"}}, nil
}

func (providerStub) ReverseGeocode(context.Context, domain.Coordinates) (*domain.Place, error) {
	return &domain.Place{Name: "Pagadian City"}, nil
}

func (providerStub) Route(context.Context, domain.Coordinates, domain.Coordinates) (*domain.Route, error) {
	return &domain.Route{DistanceKm: 1}, nil
}

func TestServiceRejectsEmptySearch(t *testing.T) {
	service := NewService(providerStub{})
	_, err := service.Search(context.Background(), "  ", domain.Coordinates{})
	if err != ErrEmptySearch {
		t.Fatalf("expected ErrEmptySearch, got %v", err)
	}
}

func TestServiceDelegatesSearch(t *testing.T) {
	service := NewService(providerStub{})
	places, err := service.Search(context.Background(), "Pagadian", domain.Coordinates{})
	if err != nil {
		t.Fatalf("search failed: %v", err)
	}
	if len(places) != 1 || places[0].Name != "Pagadian City" {
		t.Fatalf("unexpected places: %#v", places)
	}
}
