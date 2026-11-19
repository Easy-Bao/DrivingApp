package ws

import (
	"context"
	"log/slog"
	"strings"
	"sync"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

const (
	_outboundQueueSize            = 64
	_defaultMaxGlobalConnections  = 10_000
	_defaultMaxUserConnections    = 8
)

// Hub owns local WebSocket queues. Priority buffer eviction drops telemetry and
// chat events first when a queue reaches capacity to protect critical lifecycle events
// and avoid terminating mobile connections during cellular network jitter.
type Hub struct {
	mutex          sync.RWMutex
	topics         map[string]map[*Subscription]struct{}
	closed         bool
	maxGlobal      int
	maxPerSubject  int
	totalConns     int
	subjectConns   map[string]int
	activeConns    sync.WaitGroup
}

type HubOption func(*Hub)

func WithConnectionLimits(maxGlobal, maxPerSubject int) HubOption {
	return func(hub *Hub) {
		if maxGlobal > 0 {
			hub.maxGlobal = maxGlobal
		}
		if maxPerSubject > 0 {
			hub.maxPerSubject = maxPerSubject
		}
	}
}

type Subscription struct {
	hub           *Hub
	topics        []string
	events        chan event.Envelope
	evictionMutex sync.Mutex
	closed        bool
	once          sync.Once
}

func NewHub(options ...HubOption) *Hub {
	hub := &Hub{
		topics:        make(map[string]map[*Subscription]struct{}),
		maxGlobal:     _defaultMaxGlobalConnections,
		maxPerSubject: _defaultMaxUserConnections,
		subjectConns:  make(map[string]int),
	}
	for _, option := range options {
		if option != nil {
			option(hub)
		}
	}
	return hub
}

// AcquireConnection reserves a connection slot for subject while respecting
// global and per-user caps and hub shutdown state. Callers must invoke the
// returned release function when the connection terminates.
func (hub *Hub) AcquireConnection(subject string) (func(), bool) {
	if hub == nil {
		return func() {}, false
	}
	hub.mutex.Lock()
	defer hub.mutex.Unlock()
	if hub.closed {
		return func() {}, false
	}
	if hub.maxGlobal > 0 && hub.totalConns >= hub.maxGlobal {
		return func() {}, false
	}
	if subject != "" && hub.maxPerSubject > 0 && hub.subjectConns[subject] >= hub.maxPerSubject {
		return func() {}, false
	}
	hub.totalConns++
	if subject != "" {
		hub.subjectConns[subject]++
	}
	hub.activeConns.Add(1)
	var releaseOnce sync.Once
	return func() {
		releaseOnce.Do(func() {
			hub.mutex.Lock()
			hub.totalConns--
			if subject != "" {
				if hub.subjectConns[subject] <= 1 {
					delete(hub.subjectConns, subject)
				} else {
					hub.subjectConns[subject]--
				}
			}
			hub.mutex.Unlock()
			hub.activeConns.Done()
		})
	}, true
}

// Wait blocks until all acquired WebSocket connections have exited or ctx expires.
func (hub *Hub) Wait(ctx context.Context) error {
	if hub == nil {
		return nil
	}
	done := make(chan struct{})
	go func() {
		defer close(done)
		hub.activeConns.Wait()
	}()
	select {
	case <-done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
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
		subscription.once.Do(func() {})
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
	topics := envelope.Topics()
	if len(topics) == 0 {
		return
	}

	hub.mutex.RLock()
	if hub.closed {
		hub.mutex.RUnlock()
		return
	}

	var targets []*Subscription
	if len(topics) == 1 {
		subscribers := hub.topics[topics[0]]
		if len(subscribers) > 0 {
			targets = make([]*Subscription, 0, len(subscribers))
			for subscription := range subscribers {
				targets = append(targets, subscription)
			}
		}
	} else {
		delivered := make(map[*Subscription]struct{})
		for _, topic := range topics {
			for subscription := range hub.topics[topic] {
				if _, duplicate := delivered[subscription]; duplicate {
					continue
				}
				delivered[subscription] = struct{}{}
				targets = append(targets, subscription)
			}
		}
	}
	hub.mutex.RUnlock()

	if len(targets) == 0 {
		return
	}

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
		event.ChatMessagesRead,
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

	drained := make([]event.Envelope, 0, _outboundQueueSize)
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

	keep := false
	if len(drained) < _outboundQueueSize {
		// The consumer freed at least one slot between the non-blocking send
		// attempt and the drain loop; preserve every buffered event.
		drained = append(drained, envelope)
		keep = true
	} else if droppableIndex != -1 {
		drained = append(drained[:droppableIndex], drained[droppableIndex+1:]...)
		drained = append(drained, envelope)
		keep = true
	} else if isDroppable(envelope.Type) {
		// No droppable events exist in buffer; all are critical.
		// Discard incoming droppable event to preserve critical queue and avoid closing connection.
		keep = true
	}

	for _, bufferedEvent := range drained {
		subscription.events <- bufferedEvent
	}
	return keep
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
		if !subscription.closed {
			subscription.closed = true
			close(subscription.events)
		}
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
