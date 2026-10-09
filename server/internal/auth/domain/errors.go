package domain

import "errors"

const MaxOTPVerificationAttempts int64 = 5

var (
	ErrInvalidCredentials          = errors.New("invalid credentials")
	ErrUserNotFound                = errors.New("user not found")
	ErrInvalidRefreshToken         = errors.New("invalid refresh token")
	ErrRefreshSessionUnavailable   = errors.New("refresh session unavailable")
	ErrEmailTaken                  = errors.New("email already registered")
	ErrInvalidEmail                = errors.New("email address is invalid")
	ErrEmailUnchanged              = errors.New("email address is unchanged")
	ErrEmailChangeStale            = errors.New("email change request is no longer valid")
	ErrAccountConflict             = errors.New("email or phone already registered")
	ErrInvalidRole                 = errors.New("invalid account role")
	ErrOTPRequired                 = errors.New("otp is required")
	ErrInvalidOTP                  = errors.New("invalid or expired otp")
	ErrOTPMaxAttemptsExceeded      = errors.New("maximum otp verification attempts exceeded")
	ErrOTPUnavailable              = errors.New("otp delivery is unavailable")
	ErrPendingRegistrationNotFound = errors.New("pending registration not found")
)
