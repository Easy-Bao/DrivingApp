package adapter

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"sync"
	"time"

	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	redisclient "github.com/redis/go-redis/v9"
)

const (
	_redisRetryInitial = 100 * time.Millisecond
	_redisRetryMaximum = 5 * time.Second
	_redisStablePeriod = time.Minute
)

// RedisEventSubscriber forwards events published by other application
// processes to this process's sinks. It reconnects after Redis disconnects.
type RedisEventSubscriber struct {
	client  *redisclient.Client
	origin  string
	channel string
	sinks   []Sink
	logger  *slog.Logger
	ready   chan struct{}
	once    sync.Once
}

func (subscriber *RedisEventSubscriber) WithLogger(logger *slog.Logger) *RedisEventSubscriber {
	if subscriber != nil && logger != nil {
		subscriber.logger = logger
	}
	return subscriber
}

func (subscriber *RedisEventSubscriber) Ready() <-chan struct{} {
	if subscriber == nil || subscriber.ready == nil {
		closed := make(chan struct{})
		close(closed)
		return closed
	}
	return subscriber.ready
}

// Run blocks until ctx is canceled. The readiness channel closes after the
// first successful subscription, allowing the HTTP server to start only after
// this process can receive cross-node events.
func (subscriber *RedisEventSubscriber) Run(ctx context.Context) error {
	if subscriber == nil || subscriber.client == nil {
		return errors.New("subscribe to realtime events: redis client is required")
	}
	if ctx == nil {
		return errors.New("subscribe to realtime events: context is required")
	}

	retryDelay := _redisRetryInitial
	for ctx.Err() == nil {
		pubsub := subscriber.client.Subscribe(ctx, subscriber.channel)
		stopCloseOnCancel := make(chan struct{})
		closeWatcherDone := make(chan struct{})
		go func() {
			defer close(closeWatcherDone)
			select {
			case <-ctx.Done():
				_ = pubsub.Close()
			case <-stopCloseOnCancel:
			}
		}()

		_, err := pubsub.Receive(ctx)
		var connectedAt time.Time
		if err == nil {
			connectedAt = time.Now()
			subscriber.once.Do(func() { close(subscriber.ready) })
			err = subscriber.receive(ctx, pubsub)
		}

		close(stopCloseOnCancel)
		<-closeWatcherDone
		_ = pubsub.Close()
		if ctx.Err() != nil {
			return nil
		}
		if !connectedAt.IsZero() && time.Since(connectedAt) >= _redisStablePeriod {
			retryDelay = _redisRetryInitial
		}
		subscriber.log().WarnContext(
			ctx,
			"redis realtime event subscription disconnected; retrying",
			"error", err,
			"retry_in", retryDelay,
		)
		if !waitForRedisRetry(ctx, retryDelay) {
			return nil
		}
		retryDelay = nextRedisRetry(retryDelay)
	}
	return nil
}

func (subscriber *RedisEventSubscriber) receive(ctx context.Context, pubsub *redisclient.PubSub) error {
	for ctx.Err() == nil {
		message, err := pubsub.ReceiveMessage(ctx)
		if err != nil {
			return fmt.Errorf("receive redis realtime event: %w", err)
		}
		if err := subscriber.dispatch(message.Payload); err != nil {
			subscriber.log().WarnContext(ctx, "ignore invalid redis realtime event", "error", err)
		}
	}
	return ctx.Err()
}

func (subscriber *RedisEventSubscriber) dispatch(payload string) error {
	var frame redisEventFrame
	if err := json.Unmarshal([]byte(payload), &frame); err != nil {
		return fmt.Errorf("decode redis realtime event frame: %w", err)
	}
	if frame.Origin == "" || len(frame.Envelope) == 0 {
		return errors.New("redis realtime event frame is incomplete")
	}
	if frame.Origin == subscriber.origin {
		return nil
	}

	envelope, err := events.Decode(frame.Envelope)
	if err != nil {
		return fmt.Errorf("decode redis realtime event envelope: %w", err)
	}
	for _, sink := range subscriber.sinks {
		sink.Publish(envelope)
	}
	return nil
}

func (subscriber *RedisEventSubscriber) log() *slog.Logger {
	if subscriber != nil && subscriber.logger != nil {
		return subscriber.logger
	}
	return slog.Default()
}

func waitForRedisRetry(ctx context.Context, delay time.Duration) bool {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return false
	case <-timer.C:
		return true
	}
}

func nextRedisRetry(delay time.Duration) time.Duration {
	if delay >= _redisRetryMaximum/2 {
		return _redisRetryMaximum
	}
	return delay * 2
}
