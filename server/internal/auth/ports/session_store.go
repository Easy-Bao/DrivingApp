package ports

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

// SessionStore persists refresh-session rotation and revocation state.
type SessionStore interface {
	Create(ctx context.Context, session domain.RefreshSession) error
	FindActive(ctx context.Context, tokenHash string, now time.Time) (domain.RefreshSession, error)
	Rotate(ctx context.Context, tokenHash string, replacement domain.RefreshSession, now time.Time) error
	Revoke(ctx context.Context, tokenHash string, now time.Time) error
	RevokeAll(ctx context.Context, userID int, now time.Time) error
}
