package application

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
)

const otpLifetime = 10 * time.Minute

type OTPService struct {
	users         authports.VerifiedUserStore
	store         authports.OTPStore
	gateway       authports.OTPSender
	tokens        authports.TokenIssuer
	sessions      authports.SessionStore
	pending       authports.PendingRegistrationStore
	registrations *RegisterService
	logger        *slog.Logger
}

func NewOTPService(
	users authports.VerifiedUserStore,
	store authports.OTPStore,
	gateway authports.OTPSender,
	tokens authports.TokenIssuer,
	sessions authports.SessionStore,
) *OTPService {
	return &OTPService{
		users:    users,
		store:    store,
		gateway:  gateway,
		tokens:   tokens,
		sessions: sessions,
		logger:   slog.Default(),
	}
}

func NewOTPServiceWithPending(
	users authports.VerifiedUserStore,
	store authports.OTPStore,
	gateway authports.OTPSender,
	tokens authports.TokenIssuer,
	pending authports.PendingRegistrationStore,
	registrations *RegisterService,
	sessions authports.SessionStore,
) *OTPService {
	return &OTPService{
		users:         users,
		store:         store,
		gateway:       gateway,
		tokens:        tokens,
		sessions:      sessions,
		pending:       pending,
		registrations: registrations,
		logger:        slog.Default(),
	}
}

func (service *OTPService) WithLogger(logger *slog.Logger) *OTPService {
	if service != nil && logger != nil {
		service.logger = logger
	}
	return service
}

func (service *OTPService) RegisterPassenger(
	ctx context.Context,
	input RegisterInput,
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
	if err := service.pending.Put(ctx, registration, otpLifetime); err != nil {
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
		if errors.Is(err, domain.ErrInvalidOTP) {
			return domain.User{}, "", domain.ErrInvalidOTP
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
		token, err := issueToken(service.tokens, strconv.Itoa(account.ID), account.Role)
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
	return issueRefreshToken(
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
		if errors.Is(err, domain.ErrInvalidOTP) {
			return domain.ErrInvalidOTP
		}
		service.log().WarnContext(ctx, "consume password reset otp failed", "error", err)
		return domain.ErrOTPUnavailable
	}
	if service.sessions == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	if err := service.sessions.RevokeAll(ctx, account.ID, time.Now().UTC()); err != nil {
		return unavailableSessionError(err)
	}
	passwordHash, err := HashPasswordWithError(password)
	if err != nil {
		return fmt.Errorf("hash reset password: %w", err)
	}
	if err := service.users.UpdatePassword(ctx, account.ID, passwordHash); err != nil {
		return fmt.Errorf("update reset password: %w", err)
	}
	return nil
}

func (service *OTPService) requestCode(ctx context.Context, purpose, email string) error {
	if service == nil || service.store == nil || service.gateway == nil {
		return domain.ErrOTPUnavailable
	}
	code, err := generateOTP()
	if err != nil {
		return fmt.Errorf("generate otp: %w", err)
	}
	if err := service.store.Put(ctx, purpose, email, code, otpLifetime); err != nil {
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
