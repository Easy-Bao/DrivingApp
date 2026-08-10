package adapter

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	redis "github.com/redis/go-redis/v9"
)

const Channel = "driveapp.realtime.v1"

const reconnectDelay = time.Second

type Sink interface {
	Publish(event.Envelope)
}

type RedisPublisher struct {
	client *redis.Client
}

func NewRedisPublisher(client *redis.Client) *RedisPublisher {
	return &RedisPublisher{client: client}
}

func (publisher *RedisPublisher) Publish(ctx context.Context, envelope event.Envelope) error {
	encoded, err := envelope.Encode()
	if err != nil {
		return err
	}
	if err := publisher.client.Publish(ctx, Channel, encoded).Err(); err != nil {
		return fmt.Errorf("publish realtime event: %w", err)
	}
	return nil
}

type RedisSubscriber struct {
	client *redis.Client
}

func NewRedisSubscriber(client *redis.Client) *RedisSubscriber {
	return &RedisSubscriber{client: client}
}

// Run reconnects after transient Redis failures. Invalid messages are dropped:
// Redis Pub/Sub is not an authority boundary and clients recover from REST
// snapshots after reconnecting.
func (subscriber *RedisSubscriber) Run(ctx context.Context, sink Sink) error {
	for {
		if ctx.Err() != nil {
			return nil
		}
		if err := subscriber.forward(ctx, sink); err != nil && ctx.Err() == nil {
			select {
			case <-ctx.Done():
				return nil
			case <-time.After(reconnectDelay):
			}
		}
	}
}

func (subscriber *RedisSubscriber) forward(ctx context.Context, sink Sink) error {
	pubsub := subscriber.client.Subscribe(ctx, Channel)
	defer pubsub.Close()

	if _, err := pubsub.Receive(ctx); err != nil {
		if errors.Is(err, context.Canceled) {
			return nil
		}
		return fmt.Errorf("subscribe to realtime events: %w", err)
	}

	messages := pubsub.Channel()
	for {
		select {
		case <-ctx.Done():
			return nil
		case message, ok := <-messages:
			if !ok {
				return errors.New("realtime event subscription closed")
			}
			envelope, err := event.Decode([]byte(message.Payload))
			if err != nil {
				continue
			}
			sink.Publish(envelope)
		}
	}
}
