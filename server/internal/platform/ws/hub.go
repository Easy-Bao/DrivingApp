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
	mutex  sync.RWMutex
	topics map[string]map[*Subscription]struct{}
	closed bool
}

type Subscription struct {
	hub           *Hub
	topics        []string
	events        chan event.Envelope
	evictionMutex sync.Mutex
	closed        bool
	once          sync.Once
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

	hub.mutex.Lock()
	defer hub.mutex.Unlock()
	if hub.closed {
		subscription.closed = true
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
	hub.mutex.Lock()
	if hub.closed {
		hub.mutex.Unlock()
		return
	}
	hub.closed = true
	subscriptions := make(map[*Subscription]struct{})
	for _, members := range hub.topics {
		for subscription := range members {
			subscriptions[subscription] = struct{}{}
		}
	}
	hub.mutex.Unlock()

	for subscription := range subscriptions {
		subscription.Close()
	}
}

func (hub *Hub) Publish(envelope event.Envelope) {
	hub.mutex.RLock()
	var targets []*Subscription
	delivered := make(map[*Subscription]struct{})
	for _, topic := range envelope.Topics() {
		for subscription := range hub.topics[topic] {
			if _, duplicate := delivered[subscription]; duplicate {
				continue
			}
			delivered[subscription] = struct{}{}
			targets = append(targets, subscription)
		}
	}
	hub.mutex.RUnlock()

	var slowSubscriptions []*Subscription
	for _, subscription := range targets {
		if !subscription.deliver(envelope) {
			slowSubscriptions = append(slowSubscriptions, subscription)
		}
	}

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
	// Every producer serializes on evictionMutex. Eviction drains and refills
	// the queue, so a lock-free enqueue could consume the freed capacity and
	// make the refill block forever while the hub read lock is held. With a
	// single producer at a time, refilling at most the drained count can never
	// block because the consumer only frees more space.
	subscription.evictionMutex.Lock()
	defer subscription.evictionMutex.Unlock()

	if subscription.closed {
		return true
	}

	select {
	case subscription.events <- envelope:
		return true
	default:
	}

	var drained []event.Envelope
drainLoop:
	for {
		select {
		case bufferedEvent, ok := <-subscription.events:
			if !ok {
				return false
			}
			drained = append(drained, bufferedEvent)
		default:
			break drainLoop
		}
	}

	droppableIndex := -1
	for index, bufferedEvent := range drained {
		if isDroppable(bufferedEvent.Type) {
			droppableIndex = index
			break
		}
	}

	if droppableIndex != -1 {
		drained = append(drained[:droppableIndex], drained[droppableIndex+1:]...)
		drained = append(drained, envelope)
		for _, bufferedEvent := range drained {
			subscription.events <- bufferedEvent
		}
		return true
	}

	// No droppable events exist in buffer; all are critical.
	// If incoming envelope is droppable, discard it to preserve critical queue and avoid closing connection.
	if isDroppable(envelope.Type) {
		for _, bufferedEvent := range drained {
			subscription.events <- bufferedEvent
		}
		return true
	}

	for _, bufferedEvent := range drained {
		subscription.events <- bufferedEvent
	}
	return false
}

func (hub *Hub) topicSubscriberCount(topic string) int {
	hub.mutex.RLock()
	defer hub.mutex.RUnlock()
	return len(hub.topics[topic])
}

func (subscription *Subscription) Events() <-chan event.Envelope {
	return subscription.events
}

func (subscription *Subscription) Close() {
	subscription.once.Do(func() {
		subscription.hub.mutex.Lock()
		defer subscription.hub.mutex.Unlock()
		for _, topic := range subscription.topics {
			members := subscription.hub.topics[topic]
			delete(members, subscription)
			if len(members) == 0 {
				delete(subscription.hub.topics, topic)
			}
		}
		subscription.evictionMutex.Lock()
		subscription.closed = true
		close(subscription.events)
		subscription.evictionMutex.Unlock()
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
