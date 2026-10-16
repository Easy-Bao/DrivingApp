package app

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
)

// EmailChangeNotifier alerts the previous address after a verified email change.
type EmailChangeNotifier interface {
	NotifyEmailChanged(ctx context.Context, previousEmail, newEmail string) error
}

// EmailChangeStore updates a verified account email only if its current value is unchanged.
type EmailChangeStore interface {
	UpdateEmail(ctx context.Context, userID int, expectedEmail, newEmail string) error
}

// OTPSender isolates OTP use cases from the delivery provider.
type OTPSender interface {
	Send(ctx context.Context, email, code string) error
}

// OTPStore owns the short-lived, single-use state used by verification flows.
type OTPStore interface {
	Put(ctx context.Context, purpose, email, code string, ttl time.Duration) error
	Consume(ctx context.Context, purpose, email, code string) error
}

// PendingRegistrationStore keeps incomplete registrations out of the user store
// until verification succeeds.
type PendingRegistrationStore interface {
	Put(ctx context.Context, registration domain.PendingRegistration, ttl time.Duration) error
	Get(ctx context.Context, email string) (domain.PendingRegistration, error)
	Delete(ctx context.Context, email string) error
}

// SessionStore owns refresh-token rotation and revocation state. Implementations
// must preserve rotation atomicity.
type SessionStore interface {
	Create(ctx context.Context, session domain.RefreshSession) error
	FindActive(ctx context.Context, tokenHash string, now time.Time) (domain.RefreshSession, error)
	Rotate(ctx context.Context, tokenHash string, replacement domain.RefreshSession, now time.Time) error
	Revoke(ctx context.Context, tokenHash string, now time.Time) error
	RevokeAll(ctx context.Context, userID int, now time.Time) error
}

// TokenIssuer keeps token signing behind the auth application boundary.
type TokenIssuer interface {
	Issue(subject string) (string, error)
}

// UserStore isolates account commands and queries from persistence details.
type UserStore interface {
	Create(ctx context.Context, user domain.User) (domain.User, error)
	FindByEmail(ctx context.Context, email string) (domain.User, error)
	FindByID(ctx context.Context, id int) (domain.User, error)
	UpdatePassword(ctx context.Context, id int, passwordHash string) error
}

// VerifiedUserStore adds the state change required after OTP verification.
type VerifiedUserStore interface {
	UserStore
	MarkVerified(ctx context.Context, id int) error
}
