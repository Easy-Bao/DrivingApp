package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

// Provider is the location module's outbound mapping-provider port.
type Provider interface {
	Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error)
	Nearby(ctx context.Context, origin domain.Coordinates, page int) ([]domain.Place, error)
	ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error)
	Route(ctx context.Context, origin, destination domain.Coordinates, options domain.RouteOptions) (*domain.Route, error)
	Matrix(ctx context.Context, origin domain.Coordinates, destinations []domain.Coordinates) (*domain.Matrix, error)
}
