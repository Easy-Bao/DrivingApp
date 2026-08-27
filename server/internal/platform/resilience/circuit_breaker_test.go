package resilience

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestCircuitBreakerOpensAfterThreshold(t *testing.T) {
	breaker := NewCircuitBreaker(2, time.Minute)
	failure := errors.New("downstream failed")
	operation := func(context.Context) error { return failure }

	if err := breaker.Do(context.Background(), operation); !errors.Is(err, failure) {
		t.Fatalf("first error = %v, want downstream failure", err)
	}
	if err := breaker.Do(context.Background(), operation); !errors.Is(err, failure) {
		t.Fatalf("second error = %v, want downstream failure", err)
	}
	if err := breaker.Do(context.Background(), operation); !errors.Is(err, ErrCircuitOpen) {
		t.Fatalf("third error = %v, want circuit open", err)
	}
}

func TestCircuitBreakerAllowsOneProbeAfterReset(t *testing.T) {
	breaker := NewCircuitBreaker(1, time.Millisecond)
	failure := errors.New("downstream failed")
	if err := breaker.Do(context.Background(), func(context.Context) error { return failure }); err == nil {
		t.Fatal("expected initial failure")
	}
	time.Sleep(2 * time.Millisecond)
	if err := breaker.Do(context.Background(), func(context.Context) error { return nil }); err != nil {
		t.Fatalf("probe error = %v, want nil", err)
	}
	if err := breaker.Do(context.Background(), func(context.Context) error { return nil }); err != nil {
		t.Fatalf("post-probe error = %v, want nil", err)
	}
}

func TestCircuitBreakerRejectsMissingDependencies(t *testing.T) {
	var breaker *CircuitBreaker
	if err := breaker.Do(context.Background(), func(context.Context) error { return nil }); !errors.Is(err, ErrCircuitNotConfigured) {
		t.Fatalf("nil breaker error = %v, want %v", err, ErrCircuitNotConfigured)
	}

	configured := NewCircuitBreaker(1, time.Minute)
	if err := configured.Do(nil, func(context.Context) error { return nil }); !errors.Is(err, ErrCircuitContextNil) {
		t.Fatalf("nil context error = %v, want %v", err, ErrCircuitContextNil)
	}
	if err := configured.Do(context.Background(), nil); !errors.Is(err, ErrCircuitOperationNil) {
		t.Fatalf("nil operation error = %v, want %v", err, ErrCircuitOperationNil)
	}
}
