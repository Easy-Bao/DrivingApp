package domain

import "errors"

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrEmailTaken         = errors.New("email already registered")
	ErrInvalidRole        = errors.New("invalid account role")
	ErrOTPRequired        = errors.New("otp is required")
	ErrInvalidOTP         = errors.New("invalid or expired otp")
	ErrOTPUnavailable     = errors.New("otp delivery is unavailable")
)
