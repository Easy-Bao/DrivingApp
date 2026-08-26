package domain

import "context"

type Provider interface {
	Search(ctx context.Context, query string, origin Coordinates) ([]Place, error)
	Nearby(ctx context.Context, origin Coordinates, page int) ([]Place, error)
	ReverseGeocode(ctx context.Context, coordinates Coordinates) (*Place, error)
	Route(ctx context.Context, origin, destination Coordinates, options RouteOptions) (*Route, error)
	Matrix(ctx context.Context, origin Coordinates, destinations []Coordinates) (*Matrix, error)
}

type Cache interface {
	Get(ctx context.Context, key string, target any) error
	Set(ctx context.Context, key string, value any) error
}
