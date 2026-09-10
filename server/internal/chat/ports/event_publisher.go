package ports

import (
	"context"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

// EventPublisher delivers chat notifications to the process-local event
// transport. REST remains the recovery path for transient delivery gaps.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
