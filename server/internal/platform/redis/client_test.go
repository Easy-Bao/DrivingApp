package redis

import (
	"context"
	"testing"
)

func TestOpenRedisWithContextStopsBeforeOpeningWhenCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := OpenWithContext(ctx, "redis://localhost:6379/0")
	if err != context.Canceled {
		t.Fatalf("error = %v, want context canceled", err)
	}
}
