package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"strconv"
	"strings"
	"time"
)

func (service *OTPService) RequestEmailChange(
	ctx context.Context,
	userID int,
	currentPassword string,
	newEmail string,
) error {
	if service == nil || service.users == nil || service.emailChanges == nil ||
		service.store == nil || service.gateway == nil {
		return domain.ErrOTPUnavailable
	}
	if userID <= 0 || currentPassword == "" {
		return domain.ErrInvalidCredentials
	}
	newEmail, err := normalizeChangeEmail(newEmail)
	if err != nil {
		return err
	}
	account, err := service.users.FindByID(ctx, userID)
	if err != nil {
		if !errors.Is(err, domain.ErrUserNotFound) {
			service.log().WarnContext(ctx, "load account for email change failed", "error", err)
			return domain.ErrOTPUnavailable
		}
		return domain.ErrInvalidCredentials
	}
	if account.ID != userID || !account.IsVerified || !security.VerifyPassword(account.PasswordHash, currentPassword) {
		return domain.ErrInvalidCredentials
	}
	if !account.IsActive() {
		return domain.ErrAccountSuspended
	}
	if strings.EqualFold(strings.TrimSpace(account.Email), newEmail) {
		return domain.ErrEmailUnchanged
	}
	if err := service.ensureEmailAvailable(ctx, userID, newEmail); err != nil {
		return err
	}

	code, err := service.generateOTP()
	if err != nil {
		return fmt.Errorf("generate email change otp: %w", err)
	}
	purpose := emailChangePurpose(userID, account.Email, newEmail)
	userKey := strconv.Itoa(userID)
	if err := service.store.Put(ctx, purpose, userKey, code, _otpLifetime); err != nil {
		service.log().WarnContext(ctx, "store email change otp failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	if err := service.gateway.Send(ctx, newEmail, code); err != nil {
		service.deleteOTP(ctx, purpose, userKey)
		service.log().WarnContext(ctx, "send email change otp failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	return nil
}

func (service *OTPService) ConfirmEmailChange(
	ctx context.Context,
	userID int,
	newEmail string,
	code string,
) error {
	if service == nil || service.users == nil || service.emailChanges == nil || service.store == nil {
		return domain.ErrOTPUnavailable
	}
	if userID <= 0 {
		return domain.ErrInvalidCredentials
	}
	newEmail, err := normalizeChangeEmail(newEmail)
	if err != nil {
		return err
	}
	code = strings.TrimSpace(code)
	if code == "" {
		return domain.ErrOTPRequired
	}
	account, err := service.users.FindByID(ctx, userID)
	if err != nil {
		if !errors.Is(err, domain.ErrUserNotFound) {
			service.log().WarnContext(ctx, "load account to confirm email change failed", "error", err)
			return domain.ErrOTPUnavailable
		}
		return domain.ErrInvalidCredentials
	}
	if account.ID != userID || !account.IsVerified {
		return domain.ErrInvalidCredentials
	}
	if !account.IsActive() {
		return domain.ErrAccountSuspended
	}
	if strings.EqualFold(strings.TrimSpace(account.Email), newEmail) {
		return domain.ErrEmailUnchanged
	}
	if err := service.ensureEmailAvailable(ctx, userID, newEmail); err != nil {
		return err
	}

	purpose := emailChangePurpose(userID, account.Email, newEmail)
	userKey := strconv.Itoa(userID)
	if err := service.store.Consume(ctx, purpose, userKey, code); err != nil {
		if errors.Is(err, domain.ErrInvalidOTP) || errors.Is(err, domain.ErrOTPMaxAttemptsExceeded) {
			return err
		}
		service.log().WarnContext(ctx, "consume email change otp failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	if err := service.emailChanges.UpdateEmail(ctx, userID, account.Email, newEmail); err != nil {
		if errors.Is(err, domain.ErrEmailTaken) || errors.Is(err, domain.ErrEmailChangeStale) {
			return err
		}
		service.log().WarnContext(ctx, "update verified account email failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	// The email is already committed and its OTP consumed, so a retry cannot
	// finish revocation. Keep the old-address notification independent of it
	// and retry revocation without the request's cancellation.
	revokeErr := service.revokeSessionsAfterEmailChange(ctx, userID)
	if service.emailNotifier != nil {
		baseCtx := ctx
		if baseCtx == nil {
			baseCtx = context.Background()
		}
		notifyCtx, cancelNotify := context.WithTimeout(
			context.WithoutCancel(baseCtx),
			_emailChangeNotifyTimeout,
		)
		notifyErr := service.emailNotifier.NotifyEmailChanged(notifyCtx, account.Email, newEmail)
		cancelNotify()
		if notifyErr != nil {
			service.log().WarnContext(ctx, "notify previous email after account change failed", "error", notifyErr)
		}
	}
	if revokeErr != nil {
		return fmt.Errorf("revoke user sessions after email change: %w", revokeErr)
	}
	return nil
}

const (
	_emailChangeRevokeAttempts = 3
	_emailChangeRevokeTimeout  = 5 * time.Second
	_emailChangeNotifyTimeout  = 10 * time.Second
	_otpCleanupTimeout         = 2 * time.Second
)

func (service *OTPService) revokeSessionsAfterEmailChange(ctx context.Context, userID int) error {
	if service.sessions == nil {
		return nil
	}
	detached := context.WithoutCancel(ctx)
	var err error
	for attempt := range _emailChangeRevokeAttempts {
		attemptCtx, cancel := context.WithTimeout(detached, _emailChangeRevokeTimeout)
		err = service.sessions.RevokeAll(attemptCtx, userID, time.Now().UTC())
		cancel()
		if err == nil {
			return nil
		}
		service.log().WarnContext(ctx, "revoke sessions after email change failed", "attempt", attempt+1, "error", err)
	}
	return err
}

func (service *OTPService) ensureEmailAvailable(ctx context.Context, userID int, email string) error {
	account, err := service.users.FindByEmail(ctx, email)
	if err == nil {
		if account.ID != 0 && account.ID != userID {
			return domain.ErrEmailTaken
		}
		return nil
	}
	if errors.Is(err, domain.ErrUserNotFound) {
		return nil
	}
	service.log().WarnContext(ctx, "check email availability failed", "error", err)
	return domain.ErrOTPUnavailable
}

func normalizeChangeEmail(raw string) (string, error) {
	email, ok := normalizeValidEmail(raw)
	if !ok {
		return "", domain.ErrInvalidEmail
	}
	return email, nil
}

func emailChangePurpose(userID int, currentEmail, newEmail string) string {
	change := strings.ToLower(strings.TrimSpace(currentEmail)) + "\x00" + newEmail
	digest := sha256.Sum256([]byte(change))
	return "email-change:" + strconv.Itoa(userID) + ":" + hex.EncodeToString(digest[:])
}
