package ws

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	ports "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
)

type envelopePublisherStub struct {
	envelope events.Envelope
	err      error
}

func (stub *envelopePublisherStub) Publish(_ context.Context, envelope events.Envelope) error {
	stub.envelope = envelope
	return stub.err
}

func TestEventPublisherBuildsAndPublishesWebSocketEnvelope(t *testing.T) {
	publisher := &envelopePublisherStub{}
	adapter := NewEventPublisher(publisher)
	err := adapter.Publish(context.Background(), ports.RealtimeEvent{
		Type: events.RideMatched,
		Scope: events.Scope{
			RideID:      "303",
			PassengerID: "7",
			DriverID:    "9",
		},
		Payload: map[string]any{
			"ride": domain.Ride{ID: 303, PassengerID: 7, Status: "accepted"},
		},
	})
	if err != nil {
		t.Fatalf("Publish() error = %v", err)
	}
	if publisher.envelope.Type != events.RideMatched ||
		publisher.envelope.Scope.RideID != "303" ||
		publisher.envelope.Scope.PassengerID != "7" ||
		publisher.envelope.Scope.DriverID != "9" {
		t.Fatalf("published envelope = %#v", publisher.envelope)
	}
	if topics := publisher.envelope.Topics(); len(topics) != 3 {
		t.Fatalf("published topics = %v, want ride, passenger, and driver topics", topics)
	}
	var payload map[string]json.RawMessage
	if err := json.Unmarshal(publisher.envelope.Payload, &payload); err != nil {
		t.Fatalf("decode published payload: %v", err)
	}
	var ride map[string]json.RawMessage
	if err := json.Unmarshal(payload["ride"], &ride); err != nil {
		t.Fatalf("decode published ride: %v", err)
	}
	if string(ride["id"]) != "303" || string(ride["status"]) != `"accepted"` {
		t.Fatalf("published ride = %s, want snake-case ride fields", payload["ride"])
	}
	if _, exists := ride["ID"]; exists {
		t.Fatalf("published ride used a domain field name: %s", payload["ride"])
	}
}

func TestEventPublisherReturnsEnvelopeDeliveryErrors(t *testing.T) {
	wantErr := errors.New("publisher unavailable")
	adapter := NewEventPublisher(&envelopePublisherStub{err: wantErr})
	err := adapter.Publish(context.Background(), ports.RealtimeEvent{
		Type:    events.RideOfferCreated,
		Scope:   events.Scope{PassengerID: "7"},
		Payload: map[string]any{},
	})
	if !errors.Is(err, wantErr) {
		t.Fatalf("Publish() error = %v, want wrapped delivery error", err)
	}
}
