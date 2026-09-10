package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/domain"
)

// Lookup reads ride assignments for authorization and active telemetry
// routing. Implementations may be backed by a projection or an authority.
type Lookup interface {
	ForRide(ctx context.Context, rideID string) (domain.Assignment, bool, error)
	ForDriver(ctx context.Context, driverID string) ([]domain.Assignment, error)
}

// Projection is an optional routing index refreshed from the authoritative
// assignment query after a cache miss or process restart.
type Projection interface {
	Lookup
	Remember(driverID string, values []domain.Assignment)
}
