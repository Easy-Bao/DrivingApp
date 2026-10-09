//go:build integration

package adapter

import (
	"context"
	"fmt"
	"net"
	"os"
	"strings"
	"testing"
	"time"

	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	redisclient "github.com/redis/go-redis/v9"
)

func TestRedisEventTransportDeliversAcrossNodes(t *testing.T) {
	redisURL := strings.TrimSpace(os.Getenv("REDIS_URL"))
	if redisURL == "" {
		t.Skip("REDIS_URL is not set")
	}

	options, err := redisclient.ParseURL(redisURL)
	if err != nil {
		t.Fatalf("parse Redis URL: %v", err)
	}
	host, _, err := net.SplitHostPort(options.Addr)
	if err != nil || (host != "localhost" && !net.ParseIP(host).IsLoopback()) {
		t.Skip("realtime event integration test requires a loopback Redis URL")
	}

	firstClient := redisclient.NewClient(options)
	secondClient := redisclient.NewClient(options)
	t.Cleanup(func() { _ = firstClient.Close() })
	t.Cleanup(func() { _ = secondClient.Close() })

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := firstClient.Ping(ctx).Err(); err != nil {
		t.Fatalf("ping local Redis: %v", err)
	}
	if err := secondClient.Ping(ctx).Err(); err != nil {
		t.Fatalf("ping local Redis from second node: %v", err)
	}

	channel := fmt.Sprintf("%s:test:%s", _redisEventChannel, events.NewID())
	firstSink := &eventCapture{events: make(chan events.Envelope, 1)}
	secondSink := &eventCapture{events: make(chan events.Envelope, 1)}
	firstPublisher, firstSubscriber := newRedisEventTransport(firstClient, channel, firstSink)
	_, secondSubscriber := newRedisEventTransport(secondClient, channel, secondSink)
	stopFirst := runRedisSubscriber(t, ctx, firstSubscriber)
	defer stopFirst()
	stopSecond := runRedisSubscriber(t, ctx, secondSubscriber)
	defer stopSecond()

	envelope, err := events.New(
		events.NewID(),
		events.RideMatched,
		time.Now().UTC(),
		events.Scope{RideID: "ride-1", PassengerID: "passenger-1", DriverID: "driver-1"},
		map[string]any{"status": "assigned"},
	)
	if err != nil {
		t.Fatalf("create event envelope: %v", err)
	}
	if err := firstPublisher.Publish(ctx, envelope); err != nil {
		t.Fatalf("publish event from first node: %v", err)
	}

	if received := receiveEvent(t, ctx, firstSink.events); received.ID != envelope.ID {
		t.Fatalf("first node event ID = %q, want %q", received.ID, envelope.ID)
	}
	if received := receiveEvent(t, ctx, secondSink.events); received.ID != envelope.ID {
		t.Fatalf("second node event ID = %q, want %q", received.ID, envelope.ID)
	}
	select {
	case duplicate := <-firstSink.events:
		t.Fatalf("first node received its own Redis event twice: %#v", duplicate)
	default:
	}
}

type eventCapture struct {
	events chan events.Envelope
}

func (capture *eventCapture) Publish(envelope events.Envelope) {
	capture.events <- envelope
}

func runRedisSubscriber(
	t *testing.T,
	ctx context.Context,
	subscriber *RedisEventSubscriber,
) func() {
	t.Helper()
	subscriberContext, cancel := context.WithCancel(ctx)
	done := make(chan error, 1)
	go func() {
		done <- subscriber.Run(subscriberContext)
	}()
	select {
	case <-subscriber.Ready():
	case err := <-done:
		cancel()
		t.Fatalf("run Redis subscriber before ready: %v", err)
	case <-ctx.Done():
		cancel()
		t.Fatalf("wait for Redis subscriber readiness: %v", ctx.Err())
	}
	return func() {
		cancel()
		select {
		case err := <-done:
			if err != nil {
				t.Errorf("stop Redis subscriber: %v", err)
			}
		case <-time.After(time.Second):
			t.Error("Redis subscriber did not stop after cancellation")
		}
	}
}

func receiveEvent(
	t *testing.T,
	ctx context.Context,
	eventChannel <-chan events.Envelope,
) events.Envelope {
	t.Helper()
	select {
	case envelope := <-eventChannel:
		return envelope
	case <-ctx.Done():
		t.Fatalf("wait for Redis event delivery: %v", ctx.Err())
		return events.Envelope{}
	}
}
