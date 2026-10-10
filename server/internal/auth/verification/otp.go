package verification

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"net/mail"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/registration"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/session"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

const _otpLifetime = 10 * time.Minute

type OTPService struct {
	users         authports.VerifiedUserStore
	emailChanges  authports.EmailChangeStore
	emailNotifier authports.EmailChangeNotifier
	store         authports.OTPStore
	gateway       authports.OTPSender
	tokens        authports.TokenIssuer
	sessions      authports.SessionStore
	pending       authports.PendingRegistrationStore
	registrations *registration.RegisterService
	logger        *slog.Logger
	hashPassword  func(string) (string, error)
}

type OTPServiceOption func(*OTPService)

type Dependencies struct {
	Users         authports.VerifiedUserStore
	EmailChanges  authports.EmailChangeStore
	EmailNotifier authports.EmailChangeNotifier
	Store         authports.OTPStore
	Gateway       authports.OTPSender
	Tokens        authports.TokenIssuer
	Sessions      authports.SessionStore
	HashPassword  func(string) (string, error)
}

func WithPendingRegistration(
	pending authports.PendingRegistrationStore,
	registrations *registration.RegisterService,
) OTPServiceOption {
	return func(service *OTPService) {
		service.pending = pending
		service.registrations = registrations
	}
}

func NewOTPService(
	dependencies Dependencies,
	options ...OTPServiceOption,
) *OTPService {
	hashPassword := dependencies.HashPassword
	if hashPassword == nil {
		hashPassword = security.HashPassword
	}
	service := &OTPService{
		users:         dependencies.Users,
		emailChanges:  dependencies.EmailChanges,
		emailNotifier: dependencies.EmailNotifier,
		store:         dependencies.Store,
		gateway:       dependencies.Gateway,
		tokens:        dependencies.Tokens,
		sessions:      dependencies.Sessions,
		logger:        slog.Default(),
		hashPassword:  hashPassword,
	}
	for _, option := range options {
		if option != nil {
			option(service)
		}
	}
	return service
}

func (service *OTPService) WithLogger(logger *slog.Logger) *OTPService {
	if service != nil && logger != nil {
		service.logger = logger
	}
	return service
}

func (service *OTPService) RegisterPassenger(
	ctx context.Context,
	input registration.RegisterInput,
) (domain.PendingRegistration, error) {
	if service == nil || service.pending == nil || service.registrations == nil {
		return domain.PendingRegistration{}, domain.ErrOTPUnavailable
	}
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if service.users != nil {
		account, err := service.users.FindByEmail(ctx, email)
		if err == nil && account.ID != 0 {
			if account.Role != domain.Passenger || account.IsVerified {
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
	if err := service.pending.Put(ctx, registration, _otpLifetime); err != nil {
		service.log().WarnContext(ctx, "store pending passenger registration failed", "error", err)
		return domain.PendingRegistration{}, fmt.Errorf(
			"%w: store pending passenger registration: %w",
			domain.ErrOTPUnavailable,
			err,
		)
	}
	if err := service.requestCode(ctx, "verification", registration.Email); err != nil {
		if cleanupErr := service.pending.Delete(ctx, registration.Email); cleanupErr != nil {
			service.log().WarnContext(ctx, "remove failed passenger registration cleanup", "error", cleanupErr)
		}
		return domain.PendingRegistration{}, fmt.Errorf("request verification code: %w", err)
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
		if account.Role != domain.Passenger {
			return domain.ErrInvalidCredentials
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
			return service.requestCode(ctx, "verification", registration.Email)
		}
		if pendingErr != nil && !errors.Is(pendingErr, domain.ErrPendingRegistrationNotFound) {
			service.log().WarnContext(ctx, "find pending registration for verification failed", "error", pendingErr)
			return domain.ErrOTPUnavailable
		}
	}
	return domain.ErrInvalidCredentials
}

func (service *OTPService) VerifyPassenger(ctx context.Context, email, code string) (domain.User, string, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if service == nil || service.store == nil || service.users == nil {
		return domain.User{}, "", domain.ErrOTPUnavailable
	}
	if err := service.store.Consume(ctx, "verification", email, strings.TrimSpace(code)); err != nil {
		if errors.Is(err, domain.ErrInvalidOTP) || errors.Is(err, domain.ErrOTPMaxAttemptsExceeded) {
			return domain.User{}, "", err
		}
		service.log().WarnContext(ctx, "consume passenger verification otp failed", "error", err)
		return domain.User{}, "", domain.ErrOTPUnavailable
	}
	account, err := service.users.FindByEmail(ctx, email)
	if err == nil && account.ID != 0 {
		if account.Role != domain.Passenger {
			return domain.User{}, "", domain.ErrInvalidOTP
		}
		if err := service.users.MarkVerified(ctx, account.ID); err != nil {
			return domain.User{}, "", fmt.Errorf("mark passenger verified: %w", err)
		}
		account.IsVerified = true
		token, err := session.IssueToken(service.tokens, strconv.Itoa(account.ID), account.Role)
		if err != nil {
			return domain.User{}, "", fmt.Errorf("issue verified passenger token: %w", err)
		}
		return account, token, nil
	}
	if err != nil && !errors.Is(err, domain.ErrUserNotFound) {
		service.log().WarnContext(ctx, "find account for passenger verification failed", "error", err)
		return domain.User{}, "", domain.ErrOTPUnavailable
	}
	if service.pending == nil || service.registrations == nil {
		return domain.User{}, "", domain.ErrInvalidOTP
	}
	registration, err := service.pending.Get(ctx, email)
	if err != nil {
		if errors.Is(err, domain.ErrPendingRegistrationNotFound) {
			return domain.User{}, "", domain.ErrInvalidOTP
		}
		service.log().WarnContext(ctx, "find pending registration for passenger verification failed", "error", err)
		return domain.User{}, "", domain.ErrOTPUnavailable
	}
	if registration.Role != domain.Passenger {
		return domain.User{}, "", domain.ErrInvalidOTP
	}
	account, token, err := service.registrations.CommitPendingPassenger(ctx, registration)
	if err != nil {
		return domain.User{}, "", fmt.Errorf("commit pending passenger registration: %w", err)
	}
	if err := service.pending.Delete(ctx, registration.Email); err != nil {
		service.log().WarnContext(ctx, "remove verified passenger registration cleanup", "error", err)
	}
	return account, token, nil
}

func (service *OTPService) IssueRefreshToken(ctx context.Context, account domain.User) (string, error) {
	if service == nil {
		return "", domain.ErrOTPUnavailable
	}
	return session.IssueRefreshToken(
		ctx,
		service.sessions,
		strconv.Itoa(account.ID),
		account.Role,
	)
}

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

func (service *OTPService) RequestPasswordResetForRole(ctx context.Context, email string, role domain.Role) error {
	if service == nil {
		return domain.ErrOTPUnavailable
	}
	account, err := service.accountForRole(ctx, email, role)
	if err != nil {
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
	if service == nil {
		return domain.ErrOTPUnavailable
	}
	account, err := service.accountForRole(ctx, email, role)
	if err != nil {
		return fmt.Errorf("find account for password reset: %w", err)
	}
	if len(password) < 8 || len([]byte(password)) > 72 {
		return domain.ErrInvalidCredentials
	}
	if service.store == nil {
		return domain.ErrOTPUnavailable
	}
	if err := service.store.Consume(ctx, "reset", account.Email, strings.TrimSpace(code)); err != nil {
		if errors.Is(err, domain.ErrInvalidOTP) || errors.Is(err, domain.ErrOTPMaxAttemptsExceeded) {
			return err
		}
		service.log().WarnContext(ctx, "consume password reset otp failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	if service.sessions == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	if err := service.sessions.RevokeAll(ctx, account.ID, time.Now().UTC()); err != nil {
		return session.UnavailableError(err)
	}
	passwordHash, err := service.hashPassword(password)
	if err != nil {
		return fmt.Errorf("hash reset password: %w", err)
	}
	if err := service.users.UpdatePassword(ctx, account.ID, passwordHash); err != nil {
		return fmt.Errorf("update reset password: %w", err)
	}
	return nil
}

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
	if strings.EqualFold(strings.TrimSpace(account.Email), newEmail) {
		return domain.ErrEmailUnchanged
	}
	if err := service.ensureEmailAvailable(ctx, userID, newEmail); err != nil {
		return err
	}

	code, err := generateOTP()
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
	if service.emailNotifier != nil {
		if err := service.emailNotifier.NotifyEmailChanged(ctx, account.Email, newEmail); err != nil {
			service.log().WarnContext(ctx, "notify previous email after account change failed", "error", err)
		}
	}
	return nil
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

func normalizeChangeEmail(email string) (string, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" || len(email) > 254 {
		return "", domain.ErrInvalidEmail
	}
	address, err := mail.ParseAddress(email)
	if err != nil || !strings.EqualFold(address.Address, email) {
		return "", domain.ErrInvalidEmail
	}
	return email, nil
}

func emailChangePurpose(userID int, currentEmail, newEmail string) string {
	change := strings.ToLower(strings.TrimSpace(currentEmail)) + "\x00" + newEmail
	digest := sha256.Sum256([]byte(change))
	return "email-change:" + strconv.Itoa(userID) + ":" + hex.EncodeToString(digest[:])
}

func (service *OTPService) requestCode(ctx context.Context, purpose, email string) error {
	if service == nil || service.store == nil || service.gateway == nil {
		return domain.ErrOTPUnavailable
	}
	code, err := generateOTP()
	if err != nil {
		return fmt.Errorf("generate otp: %w", err)
	}
	if err := service.store.Put(ctx, purpose, email, code, _otpLifetime); err != nil {
		service.log().WarnContext(ctx, "store otp failed", "error", err, "purpose", purpose)
		return fmt.Errorf("%w: store otp: %w", domain.ErrOTPUnavailable, err)
	}
	if err := service.gateway.Send(ctx, email, code); err != nil {
		service.log().WarnContext(ctx, "send otp failed", "error", err, "purpose", purpose)
		return fmt.Errorf("%w: send otp: %w", domain.ErrOTPUnavailable, err)
	}
	return nil
}

func (service *OTPService) account(ctx context.Context, email string) (domain.User, error) {
	if service == nil || service.users == nil {
		return domain.User{}, domain.ErrOTPUnavailable
	}
	return service.users.FindByEmail(ctx, strings.ToLower(strings.TrimSpace(email)))
}

func (service *OTPService) accountForRole(ctx context.Context, email string, role domain.Role) (domain.User, error) {
	account, err := service.account(ctx, email)
	if err != nil {
		if errors.Is(err, domain.ErrOTPUnavailable) {
			return domain.User{}, err
		}
		if !errors.Is(err, domain.ErrUserNotFound) {
			service.log().WarnContext(ctx, "find account for role-scoped operation failed", "error", err)
		}
		return domain.User{}, domain.ErrInvalidCredentials
	}
	if account.Role != role {
		return domain.User{}, domain.ErrInvalidCredentials
	}
	return account, nil
}

func (service *OTPService) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}

func generateOTP() (string, error) {
	var bytes [4]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return "", fmt.Errorf("read otp randomness: %w", err)
	}
	value := uint32(bytes[0])<<24 | uint32(bytes[1])<<16 | uint32(bytes[2])<<8 | uint32(bytes[3])
	return fmt.Sprintf("%06d", value%1_000_000), nil
}
