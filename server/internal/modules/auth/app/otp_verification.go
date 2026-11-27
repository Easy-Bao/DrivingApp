package app

import (
	"context"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	"strconv"
	"strings"
	"time"
)

func (service *OTPService) RegisterPassenger(
	ctx context.Context,
	input RegisterInput,
) (domain.PendingRegistration, error) {
	if service == nil || service.pending == nil || service.registrations == nil ||
		service.store == nil || service.gateway == nil {
		return domain.PendingRegistration{}, domain.ErrOTPUnavailable
	}
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if service.users != nil {
		account, err := service.users.FindByEmail(ctx, email)
		if err == nil && account.ID != 0 {
			if account.Role != domain.Passenger || account.IsVerified || !account.IsActive() {
				return domain.PendingRegistration{}, domain.ErrEmailTaken
			}
			if err := service.requestCode(ctx, "verification", account.Email); err != nil {
				return domain.PendingRegistration{}, fmt.Errorf("request verification code: %w", err)
			}
			return domain.PendingRegistration{Email: account.Email, Role: domain.Passenger}, nil
		}
		if err != nil && !errors.Is(err, domain.ErrUserNotFound) {
			service.log().WarnContext(ctx, "find account for passenger registration failed", "error", err)
			return domain.PendingRegistration{}, domain.ErrOTPUnavailable
		}
	}

	registration, err := service.registrations.PreparePassenger(ctx, input)
	if err != nil {
		return domain.PendingRegistration{}, fmt.Errorf("prepare passenger registration: %w", err)
	}
	previousPending, prevErr := service.pending.Get(ctx, registration.Email)
	hasPreviousPending := prevErr == nil
	if prevErr != nil && !errors.Is(prevErr, domain.ErrPendingRegistrationNotFound) {
		service.log().WarnContext(ctx, "check existing pending passenger registration failed", "error", prevErr)
		return domain.PendingRegistration{}, domain.ErrOTPUnavailable
	}

	code, err := service.generateOTP()
	if err != nil {
		return domain.PendingRegistration{}, fmt.Errorf("generate verification otp: %w", err)
	}
	// Replace any existing verification OTP before overwriting pending data so
	// an earlier code cannot verify a newer registration's credentials.
	if err := service.store.Put(ctx, "verification", registration.Email, code, _otpLifetime); err != nil {
		service.log().WarnContext(ctx, "store otp failed", "error", err, "purpose", "verification")
		return domain.PendingRegistration{}, fmt.Errorf("%w: store otp: %w", domain.ErrOTPUnavailable, err)
	}
	if err := service.pending.Put(ctx, registration, _otpLifetime); err != nil {
		service.deleteOTP(ctx, "verification", registration.Email)
		service.log().WarnContext(ctx, "store pending passenger registration failed", "error", err)
		return domain.PendingRegistration{}, fmt.Errorf(
			"%w: store pending passenger registration: %w",
			domain.ErrOTPUnavailable,
			err,
		)
	}
	if err := service.gateway.Send(ctx, registration.Email, code); err != nil {
		service.deleteOTP(ctx, "verification", registration.Email)
		service.log().WarnContext(ctx, "send otp failed", "error", err, "purpose", "verification")
		if hasPreviousPending {
			if restoreErr := service.pending.Put(ctx, previousPending, _otpLifetime); restoreErr != nil {
				service.log().WarnContext(ctx, "restore previous passenger registration cleanup", "error", restoreErr)
			}
		} else if cleanupErr := service.pending.Delete(ctx, registration.Email); cleanupErr != nil {
			service.log().WarnContext(ctx, "remove failed passenger registration cleanup", "error", cleanupErr)
		}
		return domain.PendingRegistration{}, fmt.Errorf("request verification code: %w: send otp: %w", domain.ErrOTPUnavailable, err)
	}
	return registration, nil
}

func (service *OTPService) RequestVerification(ctx context.Context, email string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	if service == nil || service.users == nil {
		return domain.ErrOTPUnavailable
	}
	account, err := service.users.FindByEmail(ctx, email)
	if err == nil && account.ID != 0 {
		if account.Role != domain.Passenger || account.IsVerified {
			return nil
		}
		if !account.IsActive() {
			// Match the unknown-account response so suspension is not disclosed.
			return nil
		}
		return service.requestCode(ctx, "verification", account.Email)
	}
	if err != nil && !errors.Is(err, domain.ErrUserNotFound) {
		service.log().WarnContext(ctx, "find account for verification failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	if service.pending != nil {
		registration, pendingErr := service.pending.Get(ctx, email)
		if pendingErr == nil && registration.Role == domain.Passenger {
			if putErr := service.pending.Put(ctx, registration, _otpLifetime); putErr != nil {
				service.log().WarnContext(ctx, "refresh pending registration ttl failed", "error", putErr)
				return domain.ErrOTPUnavailable
			}
			return service.requestCode(ctx, "verification", registration.Email)
		}
		if pendingErr != nil && !errors.Is(pendingErr, domain.ErrPendingRegistrationNotFound) {
			service.log().WarnContext(ctx, "find pending registration for verification failed", "error", pendingErr)
			return domain.ErrOTPUnavailable
		}
	}
	return nil
}

func (service *OTPService) VerifyPassenger(ctx context.Context, email, code string) (domain.User, string, error) {
	account, tokens, err := service.verifyPassenger(ctx, email, code, false)
	return account, tokens.AccessToken, err
}

// VerifyPassengerSession consumes the verification OTP, persists verification/account creation
// atomically with a refresh session, and returns both access and refresh tokens.
func (service *OTPService) VerifyPassengerSession(ctx context.Context, email, code string) (domain.User, SessionTokens, error) {
	return service.verifyPassenger(ctx, email, code, true)
}

func (service *OTPService) verifyPassenger(
	ctx context.Context,
	email string,
	code string,
	withSession bool,
) (domain.User, SessionTokens, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if service == nil || service.store == nil || service.users == nil {
		return domain.User{}, SessionTokens{}, domain.ErrOTPUnavailable
	}
	if withSession && service.sessions == nil {
		return domain.User{}, SessionTokens{}, domain.ErrRefreshSessionUnavailable
	}
	code = strings.TrimSpace(code)
	if code == "" {
		return domain.User{}, SessionTokens{}, domain.ErrOTPRequired
	}
	if err := service.store.Consume(ctx, "verification", email, code); err != nil {
		if errors.Is(err, domain.ErrInvalidOTP) || errors.Is(err, domain.ErrOTPMaxAttemptsExceeded) {
			return domain.User{}, SessionTokens{}, err
		}
		service.log().WarnContext(ctx, "consume passenger verification otp failed", "error", err)
		return domain.User{}, SessionTokens{}, domain.ErrOTPUnavailable
	}
	account, err := service.users.FindByEmail(ctx, email)
	if err == nil && account.ID != 0 {
		if account.Role != domain.Passenger || account.IsVerified {
			return domain.User{}, SessionTokens{}, domain.ErrInvalidOTP
		}
		if !account.IsActive() {
			return domain.User{}, SessionTokens{}, domain.ErrAccountSuspended
		}
		accessToken, err := IssueToken(service.tokens, strconv.Itoa(account.ID), account.Role)
		if err != nil {
			return domain.User{}, SessionTokens{}, fmt.Errorf("issue verified passenger token: %w", err)
		}
		var tokens SessionTokens
		tokens.AccessToken = accessToken
		if withSession {
			refreshToken, session, err := NewRefreshSession(account.ID, time.Now().UTC())
			if err != nil {
				return domain.User{}, SessionTokens{}, UnavailableError(err)
			}
			if err := service.users.MarkVerifiedWithSession(ctx, account.ID, session); err != nil {
				return domain.User{}, SessionTokens{}, fmt.Errorf("mark passenger verified with session: %w", err)
			}
			tokens.RefreshToken = refreshToken
		} else if err := service.users.MarkVerified(ctx, account.ID); err != nil {
			return domain.User{}, SessionTokens{}, fmt.Errorf("mark passenger verified: %w", err)
		}
		account.IsVerified = true
		return account, tokens, nil
	}
	if err != nil && !errors.Is(err, domain.ErrUserNotFound) {
		service.log().WarnContext(ctx, "find account for passenger verification failed", "error", err)
		return domain.User{}, SessionTokens{}, domain.ErrOTPUnavailable
	}
	if service.pending == nil || service.registrations == nil {
		return domain.User{}, SessionTokens{}, domain.ErrInvalidOTP
	}
	registration, err := service.pending.Get(ctx, email)
	if err != nil {
		if errors.Is(err, domain.ErrPendingRegistrationNotFound) {
			return domain.User{}, SessionTokens{}, domain.ErrInvalidOTP
		}
		service.log().WarnContext(ctx, "find pending registration for passenger verification failed", "error", err)
		return domain.User{}, SessionTokens{}, domain.ErrOTPUnavailable
	}
	if registration.Role != domain.Passenger {
		return domain.User{}, SessionTokens{}, domain.ErrInvalidOTP
	}
	var tokens SessionTokens
	if withSession {
		account, tokens, err = service.registrations.CommitPendingPassengerSession(ctx, registration)
		if err != nil {
			return domain.User{}, SessionTokens{}, fmt.Errorf("commit pending passenger registration with session: %w", err)
		}
	} else {
		var accessToken string
		account, accessToken, err = service.registrations.CommitPendingPassenger(ctx, registration)
		if err != nil {
			return domain.User{}, SessionTokens{}, fmt.Errorf("commit pending passenger registration: %w", err)
		}
		tokens.AccessToken = accessToken
	}
	if err := service.pending.Delete(ctx, registration.Email); err != nil {
		service.log().WarnContext(ctx, "remove verified passenger registration cleanup", "error", err)
	}
	return account, tokens, nil
}

func (service *OTPService) IssueRefreshToken(ctx context.Context, account domain.User) (string, error) {
	if service == nil {
		return "", domain.ErrOTPUnavailable
	}
	return IssueRefreshToken(
		ctx,
		service.sessions,
		strconv.Itoa(account.ID),
		account.Role,
	)
}
