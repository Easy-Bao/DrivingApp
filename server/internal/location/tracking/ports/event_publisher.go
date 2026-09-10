package ports

import (
	"context"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

// EventPublisher delivers location notifications to the process-local event
// transport. Active ride REST endpoints remain authoritative for recovery.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
