package domain

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

var (
	ErrRideAccessDenied          = errors.New("ride location access denied")
	ErrRideAssignmentUnavailable = errors.New("ride location authorization is unavailable")
)

type DriverPoint struct {
	DriverID  string  `json:"driver_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}
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

// RideAssignment is a short-lived delivery routing record, not a source of
// truth. The ride store remains authoritative during a cache miss.
type RideAssignment struct {
	RideID      string
	DriverID    string
	PassengerID string
}

type RideAssignmentLookup interface {
	ForDriver(ctx context.Context, driverID string) (RideAssignment, bool, error)
	ForRide(ctx context.Context, rideID string) (RideAssignment, bool, error)
}

type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
