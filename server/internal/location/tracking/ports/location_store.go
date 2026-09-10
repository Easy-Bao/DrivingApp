package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
)

// LocationStore is the tracking module's persistence boundary for telemetry
// and active-ride location.
type LocationStore interface {
	Upsert(ctx context.Context, point domain.DriverPoint) error
	Nearby(ctx context.Context, latitude, longitude float64, radiusKm float64) ([]domain.DriverPoint, error)
	Remove(ctx context.Context, driverID string) error
	Get(ctx context.Context, driverID string) (domain.DriverPoint, error)
	UpsertPassenger(ctx context.Context, rideID string, point domain.DriverPoint) error
	GetPassenger(ctx context.Context, rideID string) (domain.DriverPoint, error)
}
