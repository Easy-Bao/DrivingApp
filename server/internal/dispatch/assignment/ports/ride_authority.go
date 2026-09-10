package ports

import (
	"context"

	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// RideAuthority is the minimal ride read contract needed to build assignment
// views. It keeps the dispatch adapter independent from the complete ride
// persistence aggregate.
type RideAuthority interface {
	Get(ctx context.Context, id int) (ridedomain.Ride, error)
	ActiveRidesForDriver(ctx context.Context, driverID int) ([]ridedomain.Ride, error)
}
