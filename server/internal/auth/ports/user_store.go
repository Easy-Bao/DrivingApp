package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

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
