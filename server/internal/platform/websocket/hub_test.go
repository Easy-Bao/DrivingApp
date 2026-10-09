package hub

import (
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
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

func TestHubBurstDelivery(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	subscription := hub.Subscribe("driver:10")
	defer subscription.Close()

	const totalEvents = 30
	var publishers sync.WaitGroup
	for i := 0; i < totalEvents; i++ {
		envelope, err := event.New(
			fmt.Sprintf("event-%d", i),
			event.DriverLocationUpdated,
			time.Now().UTC(),
			event.Scope{DriverID: "10"},
			map[string]any{"seq": i},
		)
		if err != nil {
			t.Fatalf("New() error = %v", err)
		}
		publishers.Add(1)
		go func(envelope event.Envelope) {
			defer publishers.Done()
			hub.Publish(envelope)
		}(envelope)
	}
	publishers.Wait()

	receivedEvents := make(map[string]struct{}, totalEvents)
	for len(receivedEvents) < totalEvents {
		select {
		case received, ok := <-subscription.Events():
			if !ok {
				t.Fatal("subscription channel closed prematurely")
			}
			if _, exists := receivedEvents[received.ID]; exists {
				t.Fatalf("received duplicate event %q", received.ID)
			}
			receivedEvents[received.ID] = struct{}{}
		case <-time.After(time.Second):
			t.Fatalf("timed out waiting for burst, received %d of %d events", len(receivedEvents), totalEvents)
		}
	}
	for expected := 0; expected < totalEvents; expected++ {
		expectedID := fmt.Sprintf("event-%d", expected)
		if _, exists := receivedEvents[expectedID]; !exists {
			t.Fatalf("event %q was not delivered", expectedID)
		}
	}

	select {
	case unexpected := <-subscription.Events():
		t.Fatalf("unexpected event remaining in channel: %#v", unexpected)
	default:
	}
}

func TestHubClosesSlowSubscriptionWhenQueueIsFull(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	subscription := hub.Subscribe("driver:10")
	defer subscription.Close()

	for i := 0; i <= _outboundQueueSize; i++ {
		envelope, err := event.New(
			fmt.Sprintf("event-%d", i),
			event.DriverLocationUpdated,
			time.Now().UTC(),
			event.Scope{DriverID: "10"},
			map[string]any{"seq": i},
		)
		if err != nil {
			t.Fatalf("New() error = %v", err)
		}
		hub.Publish(envelope)
	}

	delivered := 0
	for range subscription.Events() {
		delivered++
	}
	if delivered != _outboundQueueSize {
		t.Fatalf("events delivered before slow subscription closed = %d, want %d", delivered, _outboundQueueSize)
	}
}
