package ws

import (
	"log/slog"
	"strings"
	"sync"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

const _outboundQueueSize = 64

// Hub owns local WebSocket queues. Priority buffer eviction drops telemetry and
// chat events first when a queue reaches capacity to protect critical lifecycle events
// and avoid terminating mobile connections during cellular network jitter.
type Hub struct {
	mu     sync.RWMutex
	topics map[string]map[*Subscription]struct{}
	closed bool
}

type Subscription struct {
	hub     *Hub
	topics  []string
	events  chan event.Envelope
	evictMu sync.Mutex
	closed  bool
	once    sync.Once
}

func NewHub() *Hub {
	return &Hub{topics: make(map[string]map[*Subscription]struct{})}
}

func (hub *Hub) Subscribe(topics ...string) *Subscription {
	subscription := &Subscription{
		hub:    hub,
		topics: uniqueTopics(topics),
		events: make(chan event.Envelope, _outboundQueueSize),
	}

	hub.mu.Lock()
	defer hub.mu.Unlock()
	if hub.closed {
		close(subscription.events)
		return subscription
	}
	for _, topic := range subscription.topics {
		if hub.topics[topic] == nil {
			hub.topics[topic] = make(map[*Subscription]struct{})
		}
		hub.topics[topic][subscription] = struct{}{}
	}
	return subscription
}

func (hub *Hub) Close() {
	hub.mu.Lock()
	if hub.closed {
		hub.mu.Unlock()
		return
	}
	hub.closed = true
	subscriptions := make(map[*Subscription]struct{})
	for _, members := range hub.topics {
		for subscription := range members {
			subscriptions[subscription] = struct{}{}
		}
	}
	hub.mu.Unlock()

	for subscription := range subscriptions {
		subscription.Close()
	}
}

func (hub *Hub) Publish(envelope event.Envelope) {
	hub.mu.RLock()
	delivered := make(map[*Subscription]struct{})
	var slowSubscriptions []*Subscription
	for _, topic := range envelope.Topics() {
		for subscription := range hub.topics[topic] {
			if _, duplicate := delivered[subscription]; duplicate {
				continue
			}
			delivered[subscription] = struct{}{}
			if !subscription.deliver(envelope) {
				slowSubscriptions = append(slowSubscriptions, subscription)
			}
		}
	}
	hub.mu.RUnlock()

	for _, subscription := range slowSubscriptions {
		slog.Warn(
			"closing realtime subscription with a full outbound queue",
			"queue_capacity", cap(subscription.events),
			"topic_count", len(subscription.topics),
		)
		subscription.Close()
	}
}

func isDroppable(eventType event.Type) bool {
	switch eventType {
	case event.DriverLocationUpdated,
		event.PassengerLocationUpdated,
		event.ChatMessageCreated,
		event.ChatTypingChanged,
		event.PresenceUpdated:
		return true
	default:
		return false
	}
}

func (subscription *Subscription) deliver(envelope event.Envelope) bool {
	// Fast path: enqueue without locking if channel has available capacity.
	select {
	case subscription.events <- envelope:
		return true
	default:
	}

	subscription.evictMu.Lock()
	defer subscription.evictMu.Unlock()

	if subscription.closed {
		return true
	}

	// Retry non-blocking send in case consumer drained an event.
	select {
	case subscription.events <- envelope:
		return true
	default:
	}

	// Channel is saturated at capacity (_outboundQueueSize).
	// Drain buffered items to perform priority eviction.
	var drained []event.Envelope
drainLoop:
	for {
		select {
		case e := <-subscription.events:
			drained = append(drained, e)
		default:
			break drainLoop
		}
	}

	// Find the oldest droppable event (telemetry/chat) in the buffer.
	droppableIndex := -1
	for i, e := range drained {
		if isDroppable(e.Type) {
			droppableIndex = i
			break
		}
	}

	if droppableIndex != -1 {
		// Evict the droppable event to make room for the new envelope.
		drained = append(drained[:droppableIndex], drained[droppableIndex+1:]...)
		drained = append(drained, envelope)
		for _, e := range drained {
			subscription.events <- e
		}
		return true
	}

	// No droppable events exist in buffer; all are critical.
	// If incoming envelope is droppable, discard it to preserve critical queue and avoid closing connection.
	if isDroppable(envelope.Type) {
		for _, e := range drained {
			subscription.events <- e
		}
		return true
	}

	// All buffered events are critical AND incoming envelope is critical.
	// Queue is truly saturated with critical messages.
	for _, e := range drained {
		subscription.events <- e
	}
	return false
}

func (hub *Hub) topicSubscriberCount(topic string) int {
	hub.mu.RLock()
	defer hub.mu.RUnlock()
	return len(hub.topics[topic])
}

func (subscription *Subscription) Events() <-chan event.Envelope {
	return subscription.events
}

func (subscription *Subscription) Close() {
	subscription.once.Do(func() {
		subscription.hub.mu.Lock()
		defer subscription.hub.mu.Unlock()
		for _, topic := range subscription.topics {
			members := subscription.hub.topics[topic]
			delete(members, subscription)
			if len(members) == 0 {
				delete(subscription.hub.topics, topic)
			}
		}
		subscription.evictMu.Lock()
		subscription.closed = true
		close(subscription.events)
		subscription.evictMu.Unlock()
	})
}

func uniqueTopics(topics []string) []string {
	unique := make(map[string]struct{}, len(topics))
	result := make([]string, 0, len(topics))
	for _, topic := range topics {
		trimmed := strings.TrimSpace(topic)
		if trimmed == "" {
			continue
		}
		if _, exists := unique[trimmed]; exists {
			continue
		}
		unique[trimmed] = struct{}{}
		result = append(result, trimmed)
	}
	return result
}
