package adapter

import (
	"context"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

type envelopeSink struct{ values []event.Envelope }

func (sink *envelopeSink) Publish(envelope event.Envelope) {
	sink.values = append(sink.values, envelope)
}

func TestMemoryPublisherFansOutValidatedEvents(t *testing.T) {
	first := &envelopeSink{}
	second := &envelopeSink{}
	publisher := NewMemoryPublisher(first, nil, second)
	envelope, err := event.New(
		"event-1",
		event.RideMatched,
		time.Now().UTC(),
		event.Scope{RideID: "ride-1", DriverID: "driver-1"},
		map[string]any{},
	)
	if err != nil {
		t.Fatal(err)
	}

	if err := publisher.Publish(context.Background(), envelope); err != nil {
		t.Fatalf("Publish() error = %v", err)
	}
	if len(first.values) != 1 || len(second.values) != 1 {
		t.Fatalf("sink values = %d and %d, want one event each", len(first.values), len(second.values))
	}
}

func TestMemoryPublisherRejectsInvalidEvents(t *testing.T) {
	publisher := NewMemoryPublisher(&envelopeSink{})
	if err := publisher.Publish(context.Background(), event.Envelope{}); err == nil {
		t.Fatal("Publish() accepted an invalid envelope")
	}
}
