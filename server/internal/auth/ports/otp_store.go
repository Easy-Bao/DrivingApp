package ports

import (
	"context"
	"time"
)

// OTPStore persists one-time verification codes.
type OTPStore interface {
	Put(ctx context.Context, purpose, email, code string, ttl time.Duration) error
	Consume(ctx context.Context, purpose, email, code string) error
}
