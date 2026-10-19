package event

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	redisclient "github.com/redis/go-redis/v9"
)

const _redisEventChannel = "driveapp:realtime:events:v1"

type serializedEventFrame struct {
	Origin   string          `json:"origin"`
	Envelope json.RawMessage `json:"envelope"`
}

// DistributedEventPublisher delivers each event to local sinks and publishes it for
// every other application process subscribed to the realtime channel.
type DistributedEventPublisher struct {
	client  *redisclient.Client
	origin  string
	channel string
	sinks   []Sink
}

// NewDistributedEventTransport builds the matching publisher and subscriber used by
// one application process. A process identifier prevents its subscriber from
// delivering an event a second time after the publisher already notified local
// sinks.
func NewDistributedEventTransport(
	client *redisclient.Client,
	sinks ...Sink,
) (*DistributedEventPublisher, *DistributedEventSubscriber) {
	channel := _redisEventChannel
	if client != nil {
		channel = fmt.Sprintf("%s:%d", channel, client.Options().DB)
	}
	return newDistributedEventTransport(client, channel, sinks...)
}

func newDistributedEventTransport(
	client *redisclient.Client,
	channel string,
	sinks ...Sink,
) (*DistributedEventPublisher, *DistributedEventSubscriber) {
	origin := NewID()
	filteredSinks := make([]Sink, 0, len(sinks))
	for _, sink := range sinks {
		if sink != nil {
			filteredSinks = append(filteredSinks, sink)
		}
	}

	return &DistributedEventPublisher{
		client:  client,
		origin:  origin,
		channel: channel,
		sinks:   filteredSinks,
	}, &DistributedEventSubscriber{
		client:  client,
		origin:  origin,
		channel: channel,
		sinks:   filteredSinks,
		ready:   make(chan struct{}),
	}
}

func (publisher *DistributedEventPublisher) Publish(ctx context.Context, envelope Envelope) error {
	if publisher == nil || publisher.client == nil {
		return errors.New("publish realtime event: redis client is required")
	}
	if ctx == nil {
		return errors.New("publish realtime event: context is required")
	}

	encodedEnvelope, err := envelope.Encode()
	if err != nil {
		return fmt.Errorf("publish realtime event: %w", err)
	}
	encodedFrame, err := json.Marshal(serializedEventFrame{
		Origin:   publisher.origin,
		Envelope: encodedEnvelope,
	})
	if err != nil {
		return fmt.Errorf("encode redis realtime event: %w", err)
	}

	for _, sink := range publisher.sinks {
		sink.Publish(envelope)
	}
	if err := publisher.client.Publish(ctx, publisher.channel, encodedFrame).Err(); err != nil {
		return fmt.Errorf("publish realtime event to redis: %w", err)
	}
	return nil
}
