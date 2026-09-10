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

// BidWriter retains the legacy bid command boundary.
type BidWriter interface {
	CreateBid(ctx context.Context, bid domain.Bid) (domain.Bid, error)
}

// BidAcceptanceStore keeps legacy bid acceptance atomic with ride matching.
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
