package event

import (
	"context"
	"strings"
	"testing"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

func TestDistributedSubscriberFailsFastOnInvalidClient(t *testing.T) {
	badClient := redisclient.NewClient(&redisclient.Options{
		Addr:        "127.0.0.1:54321",
		DialTimeout: 50 * time.Millisecond,
	})
	defer badClient.Close()

	_, subscriber := NewDistributedTransport(badClient)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	err := subscriber.Run(ctx)
	if err == nil {
		t.Fatal("expected Run() to fail fast when Redis is unreachable, got nil")
	}
	if !strings.Contains(err.Error(), "initial redis realtime event subscription failed") {
		t.Fatalf("unexpected error message: %v", err)
	}
}

func TestDistributedSubscriberRequiresClient(t *testing.T) {
	subscriber := &DistributedSubscriber{}
	err := subscriber.Run(context.Background())
	if err == nil {
		t.Fatal("expected error on unconfigured subscriber")
	}
	if !strings.Contains(err.Error(), "redis client is required") {
		t.Fatalf("unexpected error message: %v", err)
	}
}
