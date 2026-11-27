package app

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
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

// DriverPresenceReader is the server-owned availability check used before
// accepting driver telemetry. The mobile client's online flag is not an
// authority for publishing location.
type DriverPresenceReader interface {
	IsOnline(ctx context.Context, driverID string) (bool, error)
}

type DriverPresenceReaderFunc func(context.Context, string) (bool, error)

func (reader DriverPresenceReaderFunc) IsOnline(
	ctx context.Context,
	driverID string,
) (bool, error) {
	return reader(ctx, driverID)
}

// EventPublisher delivers location notifications to the process-local event
// transport. Active ride REST endpoints remain authoritative for recovery.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}

// RideAssignment carries active trip participants and lifecycle state for
// telemetry authorization without importing the dispatch module.
type RideAssignment struct {
	RideID      string
	DriverID    string
	PassengerID string
	Status      string
}

func (value RideAssignment) Active() bool {
	switch value.Status {
	case "assigned", "accepted", "arrived", "in_transit":
		return true
	default:
		return false
	}
}

// RideAssignmentLookup supplies driver/ride assignments needed for live telemetry.
type RideAssignmentLookup interface {
	ForDriver(ctx context.Context, driverID string) ([]RideAssignment, error)
	ForRide(ctx context.Context, rideID string) (RideAssignment, bool, error)
}
