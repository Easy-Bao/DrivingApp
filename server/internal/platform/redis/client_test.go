package redis

import (
	"context"
	"errors"
	"net"
	"strings"
	"testing"
	"time"
)

func TestOpenWithContextStopsBeforeOpeningWhenCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := OpenWithContext(ctx, "redis://localhost:6379/0")
	if err != context.Canceled {
		t.Fatalf("error = %v, want context canceled", err)
	}
}

func TestOpenWithContextKeepsCredentialsOutOfParseErrors(t *testing.T) {
	const samplePassword = "fixture-password"
	_, err := OpenWithContext(t.Context(), "redis://user:"+samplePassword+"@localhost:invalid")
	if err == nil || !strings.Contains(err.Error(), "REDIS_URL") {
		t.Fatal("expected a safe REDIS_URL configuration error")
	}
	if strings.Contains(err.Error(), samplePassword) {
		t.Fatal("Redis configuration error includes the password")
	}
}

func TestOpenWithContextBoundsStalledStartupPing(t *testing.T) {
	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen for Redis test peer: %v", err)
	}
	t.Cleanup(func() { _ = listener.Close() })

	started := time.Now()
	ctx, cancel := context.WithTimeout(t.Context(), 100*time.Millisecond)
	defer cancel()
	client, err := OpenWithContext(ctx, "redis://"+listener.Addr().String()+"?max_retries=-1&read_timeout=5s")
	if client != nil {
		_ = client.Close()
		t.Fatal("returned a Redis client without a successful startup ping")
	}
	if timeout, ok := errors.AsType[net.Error](err); !ok || !timeout.Timeout() {
		t.Fatalf("startup error = %v, want a timeout", err)
	}
	if elapsed := time.Since(started); elapsed > 2*time.Second {
		t.Fatalf("startup ping took %v despite its 100ms context deadline", elapsed)
	}
}
