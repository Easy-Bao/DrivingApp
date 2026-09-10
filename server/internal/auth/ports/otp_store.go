package ports

import (
	"context"
	"time"
)

// OTPStore owns the short-lived, single-use state used by verification flows.
type OTPStore interface {
	Put(ctx context.Context, purpose, email, code string, ttl time.Duration) error
	Consume(ctx context.Context, purpose, email, code string) error
}
