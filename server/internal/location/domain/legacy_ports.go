package domain

import "context"

// Provider is the legacy location-provider port kept for existing callers.
//
// Deprecated: use location/ports.Provider instead.
type Provider interface {
	Search(ctx context.Context, query string, origin Coordinates) ([]Place, error)
	Nearby(ctx context.Context, origin Coordinates, page int) ([]Place, error)
	ReverseGeocode(ctx context.Context, coordinates Coordinates) (*Place, error)
	Route(ctx context.Context, origin, destination Coordinates, options RouteOptions) (*Route, error)
	Matrix(ctx context.Context, origin Coordinates, destinations []Coordinates) (*Matrix, error)
}

// Cache is the legacy location-response cache port kept for existing callers.
//
// Deprecated: use location/ports.Cache instead.
type Cache interface {
	Get(ctx context.Context, key string, target any) error
	Set(ctx context.Context, key string, value any) error
}
