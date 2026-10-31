package ws

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

func TestClosedHubSubscribeAndCloseDoesNotPanic(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	hub.Close()

	sub := hub.Subscribe("driver:1")
	if _, open := <-sub.Events(); open {
		t.Fatal("subscription on closed hub should be immediately closed")
	}

	// Must not panic when Close is invoked on subscription from closed hub
	sub.Close()
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
			event.RideStatusChanged,
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

func TestHubEvictsDroppableEventsWithoutClosingSubscription(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	subscription := hub.Subscribe("driver:10")
	defer subscription.Close()

	totalTelemetry := _outboundQueueSize + 20
	for i := 0; i < totalTelemetry; i++ {
		envelope, err := event.New(
			fmt.Sprintf("telemetry-%d", i),
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

	if len(subscription.Events()) != _outboundQueueSize {
		t.Fatalf("expected queue length %d, got %d", _outboundQueueSize, len(subscription.Events()))
	}

	criticalEnvelope, err := event.New(
		"critical-1",
		event.RideStatusChanged,
		time.Now().UTC(),
		event.Scope{DriverID: "10"},
		map[string]any{"status": "in_transit"},
	)
	if err != nil {
		t.Fatalf("New() critical error = %v", err)
	}
	hub.Publish(criticalEnvelope)

	foundCritical := false
	for len(subscription.Events()) > 0 {
		received := <-subscription.Events()
		if received.ID == "critical-1" {
			foundCritical = true
		}
	}
	if !foundCritical {
		t.Fatal("expected critical event to be queued after evicting telemetry")
	}
}

func TestHubConcurrentPublishersOnFullQueueDoNotBlockClose(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	subscription := hub.Subscribe("driver:10")

	done := make(chan struct{})
	go func() {
		defer close(done)
		var publishers sync.WaitGroup
		for worker := 0; worker < 16; worker++ {
			publishers.Add(1)
			go func() {
				defer publishers.Done()
				for i := 0; i < 100; i++ {
					envelope, err := event.New(
						fmt.Sprintf("telemetry-%d-%d", worker, i),
						event.DriverLocationUpdated,
						time.Now().UTC(),
						event.Scope{DriverID: "10"},
						map[string]any{"seq": i},
					)
					if err != nil {
						t.Errorf("New() error = %v", err)
						return
					}
					hub.Publish(envelope)
				}
			}()
		}
		publishers.Wait()
		subscription.Close()
	}()

	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("concurrent publishers or Close blocked on a full queue")
	}
}

func TestHubPublishSingleAndMultiTopicFastPath(t *testing.T) {
	t.Parallel()

	hub := NewHub()
	defer hub.Close()

	// Empty topics: should safely no-op without deadlock or panic
	emptyEnvelope := event.Envelope{}
	hub.Publish(emptyEnvelope)

	subA := hub.Subscribe("driver:alpha")
	subB := hub.Subscribe("passenger:beta")
	defer subA.Close()
	defer subB.Close()

	// Single topic publishing
	singleEnvelope, err := event.New(
		"evt-single",
		event.DriverLocationUpdated,
		time.Now().UTC(),
		event.Scope{DriverID: "alpha"},
		map[string]any{},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	hub.Publish(singleEnvelope)

	// SubA receives, subB does not
	select {
	case received := <-subA.Events():
		if received.ID != "evt-single" {
			t.Fatalf("subA received ID = %q, want evt-single", received.ID)
		}
	case <-time.After(time.Second):
		t.Fatal("subA timed out waiting for single topic event")
	}

	select {
	case unexp := <-subB.Events():
		t.Fatalf("subB received unexpected event: %#v", unexp)
	default:
	}

	// Multi-topic envelope with overlap
	multiSub := hub.Subscribe("topic:gamma")
	defer multiSub.Close()

	multiEnvelope, err := event.New(
		"evt-multi",
		event.RideMatched,
		time.Now().UTC(),
		event.Scope{DriverID: "alpha", PassengerID: "beta"},
		map[string]any{},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	hub.Publish(multiEnvelope)

	for _, sub := range []*Subscription{subA, subB} {
		select {
		case received := <-sub.Events():
			if received.ID != "evt-multi" {
				t.Fatalf("received ID = %q, want evt-multi", received.ID)
			}
		case <-time.After(time.Second):
			t.Fatal("subscriber timed out waiting for multi topic event")
		}
	}
}
