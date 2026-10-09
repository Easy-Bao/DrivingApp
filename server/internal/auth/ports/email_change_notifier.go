package ports

import "context"

// EmailChangeNotifier alerts the previous address after a verified email change.
type EmailChangeNotifier interface {
	NotifyEmailChanged(ctx context.Context, previousEmail, newEmail string) error
}
