package ports

import (
	"context"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

// EventPublisher is the ride module's outbound seam for transient event
// delivery. Persistence remains authoritative when fan-out is unavailable.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
