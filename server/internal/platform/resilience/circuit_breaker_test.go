package resilience

import (
	"context"
	"errors"
	"testing"
	"testing/synctest"
	"time"
)

func TestCircuitBreakerUsesDefaultsForInvalidConfiguration(t *testing.T) {
	breaker := NewCircuitBreaker(CircuitBreakerConfig{})
	if breaker.failureThreshold != _defaultFailureThreshold {
		t.Fatalf("failure threshold = %d, want %d", breaker.failureThreshold, _defaultFailureThreshold)
	}
	if breaker.resetAfter != _defaultResetAfter {
		t.Fatalf("reset duration = %s, want %s", breaker.resetAfter, _defaultResetAfter)
	}
}

func TestCircuitBreakerOpensAfterThreshold(t *testing.T) {
	breaker := NewCircuitBreaker(CircuitBreakerConfig{
		FailureThreshold: 2,
		ResetAfter:       time.Minute,
	})
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
	synctest.Test(t, func(t *testing.T) {
		breaker := NewCircuitBreaker(CircuitBreakerConfig{
			FailureThreshold: 1,
			ResetAfter:       time.Millisecond,
		})
		failure := errors.New("downstream failed")
		if err := breaker.Do(context.Background(), func(context.Context) error { return failure }); err == nil {
			t.Fatal("expected initial failure")
		}
		timer := time.NewTimer(2 * time.Millisecond)
		defer timer.Stop()
		<-timer.C
		synctest.Wait()
		if err := breaker.Do(context.Background(), func(context.Context) error { return nil }); err != nil {
			t.Fatalf("probe error = %v, want nil", err)
		}
		if err := breaker.Do(context.Background(), func(context.Context) error { return nil }); err != nil {
			t.Fatalf("post-probe error = %v, want nil", err)
		}
	})
}

func TestCircuitBreakerRejectsMissingDependencies(t *testing.T) {
	var breaker *CircuitBreaker
	nilBreakerErr := breaker.Do(context.Background(), func(context.Context) error {
		return nil
	})
	if !errors.Is(nilBreakerErr, ErrCircuitNotConfigured) {
		t.Fatalf("nil breaker error = %v, want %v", nilBreakerErr, ErrCircuitNotConfigured)
	}

	configured := NewCircuitBreaker(CircuitBreakerConfig{
		FailureThreshold: 1,
		ResetAfter:       time.Minute,
	})
	if err := configured.Do(nil, func(context.Context) error { return nil }); !errors.Is(err, ErrCircuitContextNil) {
		t.Fatalf("nil context error = %v, want %v", err, ErrCircuitContextNil)
	}
	if err := configured.Do(context.Background(), nil); !errors.Is(err, ErrCircuitOperationNil) {
		t.Fatalf("nil operation error = %v, want %v", err, ErrCircuitOperationNil)
	}
}

func TestCircuitBreakerIgnoresCallerCancellation(t *testing.T) {
	breaker := NewCircuitBreaker(CircuitBreakerConfig{FailureThreshold: 2, ResetAfter: time.Hour})

	for range 5 {
		ctx, cancel := context.WithCancel(context.Background())
		err := breaker.Do(ctx, func(ctx context.Context) error {
			cancel()
			return ctx.Err()
		})
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("Do() error = %v, want context cancellation", err)
		}
	}

	if err := breaker.Do(context.Background(), func(context.Context) error { return nil }); err != nil {
		t.Fatalf("healthy request rejected after cancellations: %v", err)
	}
}

func TestCircuitBreakerReleasesProbeOnPanic(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		breaker := NewCircuitBreaker(CircuitBreakerConfig{
			FailureThreshold: 1,
			ResetAfter:       time.Millisecond,
		})
		failure := errors.New("downstream failed")
		if err := breaker.Do(context.Background(), func(context.Context) error { return failure }); err == nil {
			t.Fatal("expected initial failure")
		}
		timer := time.NewTimer(2 * time.Millisecond)
		defer timer.Stop()
		<-timer.C
		synctest.Wait()

		// Probe panics
		func() {
			defer func() {
				_ = recover()
			}()
			_ = breaker.Do(context.Background(), func(context.Context) error {
				panic("unexpected downstream panic")
			})
		}()

		// Breaker must not be permanently locked in half-open state
		timer2 := time.NewTimer(2 * time.Millisecond)
		defer timer2.Stop()
		<-timer2.C
		synctest.Wait()

		if err := breaker.Do(context.Background(), func(context.Context) error { return nil }); err != nil {
			t.Fatalf("post-panic probe failed: %v", err)
		}
	})
}
