package hub

import (
	"log/slog"
	"strings"
	"sync"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

const _outboundQueueSize = 64

// Hub owns local WebSocket queues. A saturated queue closes the subscription so
// the connection exposes delivery interruption instead of silently evicting
// events.
type Hub struct {
	mu     sync.RWMutex
	topics map[string]map[*Subscription]struct{}
	closed bool
}

type Subscription struct {
	hub    *Hub
	topics []string
	events chan event.Envelope
	once   sync.Once
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
			select {
			case subscription.events <- envelope:
			default:
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
		close(subscription.events)
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
