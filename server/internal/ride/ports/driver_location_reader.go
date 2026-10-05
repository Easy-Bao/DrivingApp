package ports

import (
	"context"
	"time"
)

// DriverLocation is the server-observed position used for lifecycle
// proximity checks. It deliberately does not expose a client-provided
// command coordinate as an authority.
type DriverLocation struct {
	Latitude   float64
	Longitude  float64
	ObservedAt time.Time
}

// DriverLocationReader supplies the latest server-owned telemetry point for a
// driver. Lifecycle commands must use this port instead of trusting command
// payload coordinates.
type DriverLocationReader interface {
	ReadDriverLocation(ctx context.Context, driverID int) (DriverLocation, error)
}

// DriverLocationReaderFunc adapts a function without coupling the ride
// lifecycle to the concrete telemetry adapter.
type DriverLocationReaderFunc func(context.Context, int) (DriverLocation, error)

var _ DriverLocationReader = DriverLocationReaderFunc(nil)

func (reader DriverLocationReaderFunc) ReadDriverLocation(
	ctx context.Context,
	driverID int,
) (DriverLocation, error) {
	return reader(ctx, driverID)
}
