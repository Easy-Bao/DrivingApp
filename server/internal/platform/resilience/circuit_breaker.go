package resilience

import (
	"context"
	"errors"
	"sync"
	"time"
)

var (
	ErrCircuitOpen          = errors.New("downstream circuit is open")
	ErrCircuitNotConfigured = errors.New("circuit breaker is not configured")
	ErrCircuitContextNil    = errors.New("circuit breaker context is nil")
	ErrCircuitOperationNil  = errors.New("circuit breaker operation is nil")
)

type CircuitBreaker struct {
	mu               sync.Mutex
	failureThreshold int
	resetAfter       time.Duration
	failures         int
	openedAt         time.Time
	halfOpen         bool
}

func NewCircuitBreaker(failureThreshold int, resetAfter time.Duration) *CircuitBreaker {
	if failureThreshold <= 0 {
		failureThreshold = 5
	}
	if resetAfter <= 0 {
		resetAfter = 30 * time.Second
	}
	return &CircuitBreaker{
		failureThreshold: failureThreshold,
		resetAfter:       resetAfter,
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
	if !breaker.allow(time.Now()) {
		return ErrCircuitOpen
	}

	err := operation(ctx)
	if err != nil {
		breaker.recordFailure(time.Now())
		return err
	}
	breaker.recordSuccess()
	return nil
}

func (breaker *CircuitBreaker) allow(now time.Time) bool {
	breaker.mu.Lock()
	defer breaker.mu.Unlock()
	if breaker.openedAt.IsZero() {
		return true
	}
	if now.Sub(breaker.openedAt) < breaker.resetAfter {
		return false
	}
	if breaker.halfOpen {
		return false
	}
	breaker.halfOpen = true
	return true
}

func (breaker *CircuitBreaker) recordFailure(now time.Time) {
	breaker.mu.Lock()
	defer breaker.mu.Unlock()
	breaker.failures++
	if breaker.failures >= breaker.failureThreshold {
		breaker.openedAt = now
		breaker.halfOpen = false
	}
}

func (breaker *CircuitBreaker) recordSuccess() {
	breaker.mu.Lock()
	defer breaker.mu.Unlock()
	breaker.failures = 0
	breaker.openedAt = time.Time{}
	breaker.halfOpen = false
}
