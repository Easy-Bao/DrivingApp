// Package ports defines the ride module's outbound ports.
package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// RideReader loads the ride aggregate needed by application use cases.
type RideReader interface {
	Get(ctx context.Context, id int) (domain.Ride, error)
}

// RideWriter persists a newly requested ride.
type RideWriter interface {
	CreateRide(ctx context.Context, ride domain.Ride) (domain.Ride, error)
}

// BidWriter persists the legacy ride bid command.
type BidWriter interface {
	CreateBid(ctx context.Context, bid domain.Bid) (domain.Bid, error)
}

// BidAcceptanceStore atomically accepts a legacy ride bid.
type BidAcceptanceStore interface {
	AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error)
}

// RideStore is the command-side persistence port used by the ride service.
// The more focused ports above remain available for use cases that need only
// one capability.
type RideStore interface {
	RideReader
	RideWriter
	BidWriter
	BidAcceptanceStore
}
