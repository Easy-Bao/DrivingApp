package adapter

import (
	"context"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

// Sink receives an already validated realtime envelope in the current process.
// Sinks are intentionally transport-neutral so the publisher can fan out to
// the WebSocket hub and local projections without introducing a broker.
type Sink interface {
	Publish(event.Envelope)
}

// MemoryPublisher delivers transient events synchronously to local sinks. The
// persistent ride store remains the authority; clients recover missed events
// through their REST snapshots after reconnecting.
type MemoryPublisher struct {
	sinks []Sink
}

func NewMemoryPublisher(sinks ...Sink) *MemoryPublisher {
	filtered := make([]Sink, 0, len(sinks))
	for _, sink := range sinks {
		if sink != nil {
			filtered = append(filtered, sink)
		}
	}
	return &MemoryPublisher{sinks: filtered}
}

func (publisher *MemoryPublisher) Publish(_ context.Context, envelope event.Envelope) error {
	if err := envelope.Validate(); err != nil {
		return fmt.Errorf("publish realtime event: %w", err)
	}
	for _, sink := range publisher.sinks {
		sink.Publish(envelope)
	}
	return nil
}
