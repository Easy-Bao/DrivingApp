package ports

import "context"

// OTPSender sends a verification code through an external delivery adapter.
type OTPSender interface {
	Send(ctx context.Context, email, code string) error
}
