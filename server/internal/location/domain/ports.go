package domain

import "context"

type Provider interface {
	Search(ctx context.Context, query string, origin Coordinates) ([]Place, error)
	ReverseGeocode(ctx context.Context, coordinates Coordinates) (*Place, error)
	Route(ctx context.Context, origin, destination Coordinates) (*Route, error)
}
