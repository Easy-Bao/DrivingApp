package domain

import (
	"context"
	"time"
)

type UserRepository interface {
	Create(ctx context.Context, user User) (User, error)
	FindByEmail(ctx context.Context, email string) (User, error)
	FindByID(ctx context.Context, id int) (User, error)
	UpdatePassword(ctx context.Context, id int, passwordHash string) error
}

type VerifiedUserRepository interface {
	UserRepository
	MarkVerified(ctx context.Context, id int) error
}

type ProfileProvisioner interface {
	Provision(ctx context.Context, user User) error
}

type TokenIssuer interface {
	Issue(subject string) (string, error)
}

type OTPGateway interface {
	Send(ctx context.Context, email, code string) error
}

type OTPStore interface {
	Put(ctx context.Context, purpose, email, code string, ttl time.Duration) error
	Consume(ctx context.Context, purpose, email, code string) error
}

type PendingRegistrationStore interface {
	Put(ctx context.Context, registration PendingRegistration, ttl time.Duration) error
	Get(ctx context.Context, email string) (PendingRegistration, error)
	Delete(ctx context.Context, email string) error
}
