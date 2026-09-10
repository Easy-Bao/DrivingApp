package ports

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

// PendingRegistrationStore keeps incomplete registrations out of the user store
// until verification succeeds.
type PendingRegistrationStore interface {
	Put(ctx context.Context, registration domain.PendingRegistration, ttl time.Duration) error
	Get(ctx context.Context, email string) (domain.PendingRegistration, error)
	Delete(ctx context.Context, email string) error
}
