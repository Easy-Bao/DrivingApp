package domain

import "context"

type UserRepository interface {
	Create(ctx context.Context, user User) (User, error)
	FindByEmail(ctx context.Context, email string) (User, error)
	FindByID(ctx context.Context, id int) (User, error)
	UpdatePassword(ctx context.Context, id int, passwordHash string) error
}

type TokenIssuer interface {
	Issue(subject string) (string, error)
}

type OTPGateway interface {
	Send(ctx context.Context, email, code string) error
}
