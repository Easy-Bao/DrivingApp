package app

import (
	"context"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	"strings"
	"time"
)

func (service *OTPService) RequestPasswordReset(ctx context.Context, email string) error {
	return service.RequestPasswordResetForRole(ctx, email, domain.Passenger)
}

func (service *OTPService) ResetPassword(ctx context.Context, email, code, password string) error {
	return service.ResetPasswordForRole(
		ctx,
		email,
		code,
		password,
		domain.Passenger,
	)
}

func (service *OTPService) VerifyPasswordResetOTP(ctx context.Context, email, code string) error {
	return service.VerifyPasswordResetOTPForRole(
		ctx,
		email,
		code,
		domain.Passenger,
	)
}

func (service *OTPService) VerifyPasswordResetOTPForRole(
	ctx context.Context,
	email string,
	code string,
	role domain.Role,
) error {
	if service == nil || service.store == nil || service.users == nil {
		return domain.ErrOTPUnavailable
	}
	normalizedEmail, ok := normalizeValidEmail(email)
	if !ok {
		return domain.ErrInvalidEmail
	}
	code = strings.TrimSpace(code)
	if code == "" {
		return domain.ErrOTPRequired
	}
	if err := service.store.Verify(ctx, "reset", normalizedEmail, code); err != nil {
		if errors.Is(err, domain.ErrInvalidOTP) || errors.Is(err, domain.ErrOTPMaxAttemptsExceeded) {
			return err
		}
		service.log().WarnContext(ctx, "verify password reset otp failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	if _, err := service.accountForRole(ctx, normalizedEmail, role); err != nil {
		if errors.Is(err, domain.ErrAccountSuspended) || errors.Is(err, domain.ErrOTPUnavailable) {
			return err
		}
		return domain.ErrInvalidOTP
	}
	return nil
}

func (service *OTPService) RequestPasswordResetForRole(ctx context.Context, email string, role domain.Role) error {
	if service == nil {
		return domain.ErrOTPUnavailable
	}
	normalizedEmail, ok := normalizeValidEmail(email)
	if !ok {
		return domain.ErrInvalidEmail
	}
	account, err := service.accountForRole(ctx, normalizedEmail, role)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidCredentials) || errors.Is(err, domain.ErrAccountSuspended) {
			return nil
		}
		return fmt.Errorf("find account for password reset: %w", err)
	}
	return service.requestCode(ctx, "reset", account.Email)
}

func (service *OTPService) ResetPasswordForRole(
	ctx context.Context,
	email string,
	code string,
	password string,
	role domain.Role,
) error {
	if service == nil || service.store == nil || service.users == nil {
		return domain.ErrOTPUnavailable
	}
	normalizedEmail, ok := normalizeValidEmail(email)
	if !ok {
		return domain.ErrInvalidEmail
	}
	if len(password) < 8 || len([]byte(password)) > 72 {
		return domain.ErrInvalidCredentials
	}
	code = strings.TrimSpace(code)
	if code == "" {
		return domain.ErrOTPRequired
	}
	if err := service.store.Consume(ctx, "reset", normalizedEmail, code); err != nil {
		if errors.Is(err, domain.ErrInvalidOTP) || errors.Is(err, domain.ErrOTPMaxAttemptsExceeded) {
			return err
		}
		service.log().WarnContext(ctx, "consume password reset otp failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	account, err := service.accountForRole(ctx, normalizedEmail, role)
	if err != nil {
		if errors.Is(err, domain.ErrAccountSuspended) || errors.Is(err, domain.ErrOTPUnavailable) {
			return err
		}
		return domain.ErrInvalidOTP
	}
	if service.sessions == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	if err := service.sessions.RevokeAll(ctx, account.ID, time.Now().UTC()); err != nil {
		return UnavailableError(err)
	}
	passwordHash, err := service.hashPassword(password)
	if err != nil {
		return fmt.Errorf("hash reset password: %w", err)
	}
	if err := service.users.UpdatePassword(ctx, account.ID, passwordHash); err != nil {
		return fmt.Errorf("update reset password: %w", err)
	}
	// Sessions created by logins that verified the old password between the
	// first revocation and the update are removed here; later logins are
	// rejected by the credential recheck during authentication.
	if err := service.sessions.RevokeAll(ctx, account.ID, time.Now().UTC()); err != nil {
		return UnavailableError(err)
	}
	return nil
}
