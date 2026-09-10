package ports

import "context"

// OTPSender isolates OTP use cases from the delivery provider.
type OTPSender interface {
	Send(ctx context.Context, email, code string) error
}
