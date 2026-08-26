package domain

import "errors"

var (
	ErrInvalidCredentials          = errors.New("invalid credentials")
	ErrInvalidRefreshToken         = errors.New("invalid refresh token")
	ErrRefreshSessionUnavailable   = errors.New("refresh session unavailable")
	ErrEmailTaken                  = errors.New("email already registered")
	ErrAccountConflict             = errors.New("email or phone already registered")
	ErrInvalidRole                 = errors.New("invalid account role")
	ErrOTPRequired                 = errors.New("otp is required")
	ErrInvalidOTP                  = errors.New("invalid or expired otp")
	ErrOTPUnavailable              = errors.New("otp delivery is unavailable")
	ErrPendingRegistrationNotFound = errors.New("pending registration not found")
)
