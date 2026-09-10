package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/passenger/ridecontext/domain"
)

// RecentDestinationReader reads the bounded passenger ride history used by
// the home query.
type RecentDestinationReader interface {
	ReadRecentDestinations(ctx context.Context, passengerID, limit int) ([]domain.RecentDestination, error)
}

// AddressResolver resolves the optional current map position for the home
// query without making the query depend on a concrete location provider.
type AddressResolver interface {
	ResolveAddress(ctx context.Context, coordinates domain.Coordinates) (string, error)
}

// Query is the inbound application port for the passenger home context.
type Query interface {
	Load(ctx context.Context, passengerID *int, coordinates *domain.Coordinates) (domain.RideContextSnapshot, error)
}
