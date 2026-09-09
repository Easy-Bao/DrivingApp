package application

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

// EventPublisher is the ride application's outbound seam for transient event
// delivery. Persistence remains authoritative when fan-out is unavailable.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
