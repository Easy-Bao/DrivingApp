package hub

import (
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

func TestHubDeliversOnlyToMatchingTopics(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	driver := hub.Subscribe("driver-1")
	passenger := hub.Subscribe("passenger-1")
	defer driver.Close()
	defer passenger.Close()

	envelope, err := event.New(
		"event-1",
		event.RideMatched,
		time.Now().UTC(),
		event.Scope{DriverID: "1"},
		map[string]any{},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	hub.Publish(envelope)

	select {
	case received := <-driver.Events():
		t.Fatalf("unexpected event for nonmatching driver topic: %#v", received)
	default:
	}

	matchingDriver := hub.Subscribe("driver:1")
	defer matchingDriver.Close()
	hub.Publish(envelope)
	select {
	case received := <-matchingDriver.Events():
		if received.ID != envelope.ID {
			t.Fatalf("event ID = %q, want %q", received.ID, envelope.ID)
		}
	case <-time.After(time.Second):
		t.Fatal("matching topic did not receive event")
	}
	select {
	case received := <-passenger.Events():
		t.Fatalf("unexpected event for passenger topic: %#v", received)
	default:
	}
}

func TestSubscriptionCloseRemovesTopicMembership(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	subscription := hub.Subscribe("driver:1")
	subscription.Close()

	envelope, err := event.New(
		"event-1",
		event.PresenceUpdated,
		time.Now().UTC(),
		event.Scope{DriverID: "1"},
		map[string]any{},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	hub.Publish(envelope)

	if _, open := <-subscription.Events(); open {
		t.Fatal("closed subscription remained open")
	}
}

func TestHubCloseTerminatesOpenSubscriptions(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	first := hub.Subscribe("driver:1")
	second := hub.Subscribe("passenger:1")
	hub.Close()

	for _, subscription := range []*Subscription{first, second} {
		if _, open := <-subscription.Events(); open {
			t.Fatal("hub close left a subscription open")
		}
	}
}
