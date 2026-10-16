package app

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

var ErrCacheMiss = errors.New("location cache miss")

// Cache stores bounded provider responses without coupling location use cases
// to a cache implementation.
type Cache interface {
	GetPlaces(ctx context.Context, key string) ([]domain.Place, error)
	SetPlaces(ctx context.Context, key string, places []domain.Place) error
	GetPlace(ctx context.Context, key string) (*domain.Place, error)
	SetPlace(ctx context.Context, key string, place *domain.Place) error
	GetMatrix(ctx context.Context, key string) (*domain.Matrix, error)
	SetMatrix(ctx context.Context, key string, matrix *domain.Matrix) error
}

// Provider isolates search, route, and geocoding use cases from the mapping
// vendor.
type Provider interface {
	Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error)
	Nearby(ctx context.Context, origin domain.Coordinates, page int) ([]domain.Place, error)
	ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error)
	Route(ctx context.Context, origin, destination domain.Coordinates, options domain.RouteOptions) (*domain.Route, error)
	Matrix(ctx context.Context, origin domain.Coordinates, destinations []domain.Coordinates) (*domain.Matrix, error)
}
