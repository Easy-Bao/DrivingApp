//go:build integration

package location_test

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

type providerStub struct{}

func (providerStub) Search(context.Context, string, domain.Coordinates) ([]domain.Place, error) {
	return []domain.Place{{Name: "Pagadian City"}}, nil
}

func (providerStub) Nearby(context.Context, domain.Coordinates, int) ([]domain.Place, error) {
	return []domain.Place{{Name: "Nearby Place"}}, nil
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
