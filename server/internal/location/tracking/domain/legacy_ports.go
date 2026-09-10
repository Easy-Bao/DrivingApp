package domain

import "context"

// These contracts remain temporarily for callers that still compile against
// the pre-ports package. New code must depend on tracking/ports instead.
type Repository interface {
	Upsert(ctx context.Context, point DriverPoint) error
	Nearby(ctx context.Context, latitude, longitude float64, radiusKm float64) ([]DriverPoint, error)
}

type LocationRepository interface {
	Repository
	Remove(ctx context.Context, driverID string) error
	Get(ctx context.Context, driverID string) (DriverPoint, error)
	UpsertPassenger(ctx context.Context, rideID string, point DriverPoint) error
	GetPassenger(ctx context.Context, rideID string) (DriverPoint, error)
}
