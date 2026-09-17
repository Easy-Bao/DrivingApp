// Package ports defines the ride module's outbound ports.
package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// RideReader supplies the aggregate snapshot needed for authorization and
// lifecycle decisions.
type RideReader interface {
	Get(ctx context.Context, id int) (domain.Ride, error)
}

// RideWriter is the command boundary for creating requested rides.
type RideWriter interface {
	CreateRide(ctx context.Context, ride domain.Ride) (domain.Ride, error)
}

// PassengerActiveRideChecker verifies whether a passenger currently has an
// active ride in progress.
type PassengerActiveRideChecker interface {
	HasActivePassengerRide(ctx context.Context, passengerID int) (bool, error)
}

// RideStore is the command-side persistence port used by the ride service.
// The more focused ports above remain available for use cases that need only
// one capability.
type RideStore interface {
	RideReader
	RideWriter
}

