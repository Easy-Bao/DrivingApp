package ports

import "context"

// EmailChangeStore updates a verified account email only if its current value is unchanged.
type EmailChangeStore interface {
	UpdateEmail(ctx context.Context, userID int, expectedEmail, newEmail string) error
}
