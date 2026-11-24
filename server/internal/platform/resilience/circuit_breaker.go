package resilience

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

var (
	ErrCircuitOpen          = errors.New("downstream circuit is open")
	ErrCircuitNotConfigured = errors.New("circuit breaker is not configured")
	ErrCircuitContextNil    = errors.New("circuit breaker context is nil")
	ErrCircuitOperationNil  = errors.New("circuit breaker operation is nil")
)

const (
	_defaultFailureThreshold = 5
	_defaultResetAfter       = 30 * time.Second
)

// NonTripError wraps an error that should be returned to the caller without
// counting as a downstream health failure against the circuit breaker.
type NonTripError struct {
	Err error
}

func (e NonTripError) Error() string {
	if e.Err == nil {
		return ""
	}
	return e.Err.Error()
}

func (e NonTripError) Unwrap() error {
	return e.Err
}

type breakerState uint8

const (
	stateClosed breakerState = iota
	stateOpen
	stateHalfOpen
)

type CircuitBreakerConfig struct {
	FailureThreshold int
	ResetAfter       time.Duration
}

type CircuitBreaker struct {
	mu               sync.Mutex
	failureThreshold int
	resetAfter       time.Duration
	state            breakerState
	generation       uint64
	failures         int
	openedAt         time.Time
}

func NewCircuitBreaker(config CircuitBreakerConfig) *CircuitBreaker {
	if config.FailureThreshold <= 0 {
		config.FailureThreshold = _defaultFailureThreshold
	}
	if config.ResetAfter <= 0 {
		config.ResetAfter = _defaultResetAfter
	}
	return &CircuitBreaker{
		failureThreshold: config.FailureThreshold,
		resetAfter:       config.ResetAfter,
		state:            stateClosed,
	}
}

func (breaker *CircuitBreaker) Do(ctx context.Context, operation func(context.Context) error) error {
	if breaker == nil {
		return ErrCircuitNotConfigured
	}
	if ctx == nil {
		return ErrCircuitContextNil
	}
	if operation == nil {
		return ErrCircuitOperationNil
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	generation, isProbe, allowed := breaker.allow(time.Now())
	if !allowed {
		return ErrCircuitOpen
	}

	completed := false
	defer func() {
		if !completed {
			breaker.recordFailure(generation, isProbe, time.Now())
		}
	}()

	err := operation(ctx)
	completed = true
	if err != nil {
		if errors.Is(err, context.Canceled) && errors.Is(ctx.Err(), context.Canceled) {
			// Caller cancellation says nothing about downstream health.
			breaker.release(generation, isProbe)
			return fmt.Errorf("execute circuit-protected operation: %w", err)
		}
		if nonTrip, ok := errors.AsType[NonTripError](err); ok {
			breaker.release(generation, isProbe)
			return fmt.Errorf("execute circuit-protected operation: %w", nonTrip.Unwrap())
		}
		breaker.recordFailure(generation, isProbe, time.Now())
		return fmt.Errorf("execute circuit-protected operation: %w", err)
	}
	breaker.recordSuccess(generation, isProbe)
	return nil
}

func (breaker *CircuitBreaker) allow(now time.Time) (uint64, bool, bool) {
	breaker.mu.Lock()
	defer breaker.mu.Unlock()
	switch breaker.state {
	case stateClosed:
		return breaker.generation, false, true
	case stateOpen:
		if now.Sub(breaker.openedAt) < breaker.resetAfter {
			return 0, false, false
		}
		breaker.state = stateHalfOpen
		breaker.generation++
		return breaker.generation, true, true
	default:
		return 0, false, false
	}
}

func (breaker *CircuitBreaker) recordFailure(generation uint64, isProbe bool, now time.Time) {
	breaker.mu.Lock()
	defer breaker.mu.Unlock()
	if generation != breaker.generation {
		return
	}
	if isProbe {
		breaker.state = stateOpen
		breaker.openedAt = now
		breaker.failures = breaker.failureThreshold
		breaker.generation++
		return
	}
	if breaker.state != stateClosed {
		return
	}
	breaker.failures++
	if breaker.failures >= breaker.failureThreshold {
		breaker.state = stateOpen
		breaker.openedAt = now
		breaker.generation++
	}
}

func (breaker *CircuitBreaker) recordSuccess(generation uint64, isProbe bool) {
	breaker.mu.Lock()
	defer breaker.mu.Unlock()
	if generation != breaker.generation {
		return
	}
	if isProbe && breaker.state == stateHalfOpen {
		breaker.state = stateClosed
		breaker.failures = 0
		breaker.openedAt = time.Time{}
		breaker.generation++
		return
	}
	if breaker.state == stateClosed {
		breaker.failures = 0
	}
}

func (breaker *CircuitBreaker) release(generation uint64, isProbe bool) {
	breaker.mu.Lock()
	defer breaker.mu.Unlock()
	if !isProbe || generation != breaker.generation || breaker.state != stateHalfOpen {
		return
	}
	// Return to open while preserving openedAt so the next caller can probe
	// immediately, and bump generation to fence any stale work.
	breaker.state = stateOpen
	breaker.generation++
}
