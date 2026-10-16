package event

import (
	"context"
	"testing"
	"time"
)

type envelopeSink struct{ values []Envelope }

func (sink *envelopeSink) Publish(envelope Envelope) {
	sink.values = append(sink.values, envelope)
}

func TestMemoryPublisherFansOutValidatedEvents(t *testing.T) {
	first := &envelopeSink{}
	second := &envelopeSink{}
	publisher := NewMemoryPublisher(first, nil, second)
	envelope, err := New(
		"event-1",
		RideMatched,
		time.Now().UTC(),
		Scope{RideID: "ride-1", DriverID: "driver-1"},
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
	if err := publisher.Publish(context.Background(), Envelope{}); err == nil {
		t.Fatal("Publish() accepted an invalid envelope")
	}
}
