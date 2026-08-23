package domain

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

var (
	ErrInvalidLocation           = errors.New("invalid location")
	ErrRideAccessDenied          = errors.New("ride location access denied")
	ErrRideAssignmentUnavailable = errors.New("ride location authorization is unavailable")
)

type DriverPoint struct {
	DriverID  string  `json:"driver_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Heading   float64 `json:"heading,omitempty"`
	Speed     float64 `json:"speed,omitempty"`
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

type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
