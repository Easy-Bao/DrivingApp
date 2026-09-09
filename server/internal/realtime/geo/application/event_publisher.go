package application

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

// EventPublisher is the location application's outbound seam for transient
// event delivery. The location store remains authoritative for recovery.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
