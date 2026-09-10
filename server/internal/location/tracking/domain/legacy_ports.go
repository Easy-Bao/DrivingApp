// Package domain contains the location-tracking value objects and compatibility
// contracts used by the tracking module.
package domain

import "context"

// Repository is the legacy location-tracking write and proximity port.
//
// Deprecated: use tracking/ports.LocationStore instead.
type Repository interface {
	Upsert(ctx context.Context, point DriverPoint) error
	Nearby(ctx context.Context, latitude, longitude float64, radiusKm float64) ([]DriverPoint, error)
}

// LocationRepository is the legacy full location-tracking port.
//
// Deprecated: use tracking/ports.LocationStore instead.
type LocationRepository interface {
	Repository
	Remove(ctx context.Context, driverID string) error
	Get(ctx context.Context, driverID string) (DriverPoint, error)
	UpsertPassenger(ctx context.Context, rideID string, point DriverPoint) error
	GetPassenger(ctx context.Context, rideID string) (DriverPoint, error)
}
