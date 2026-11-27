package app

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"log/slog"
	"math/big"
	"strings"
	"time"
)

const _otpLifetime = 10 * time.Minute

type OTPService struct {
	users         VerifiedUserStore
	emailChanges  EmailChangeStore
	emailNotifier EmailChangeNotifier
	store         OTPStore
	gateway       OTPSender
	tokens        TokenIssuer
	sessions      SessionStore
	pending       PendingRegistrationStore
	registrations *RegisterService
	logger        *slog.Logger
	hashPassword  func(string) (string, error)
	generateCode  func() (string, error)
}

type OTPServiceOption func(*OTPService)

type OTPDependencies struct {
	Users         VerifiedUserStore
	EmailChanges  EmailChangeStore
	EmailNotifier EmailChangeNotifier
	Store         OTPStore
	Gateway       OTPSender
	Tokens        TokenIssuer
	Sessions      SessionStore
	HashPassword  func(string) (string, error)
	GenerateCode  func() (string, error)
}

func WithPendingRegistration(
	pending PendingRegistrationStore,
	registrations *RegisterService,
) OTPServiceOption {
	return func(service *OTPService) {
		service.pending = pending
		service.registrations = registrations
	}
}

func NewOTPService(
	dependencies OTPDependencies,
	options ...OTPServiceOption,
) *OTPService {
	hashPassword := dependencies.HashPassword
	if hashPassword == nil {
		hashPassword = security.HashPassword
	}
	generateCode := dependencies.GenerateCode
	if generateCode == nil {
		generateCode = generateOTP
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
		generateCode:  generateCode,
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

func (service *OTPService) deleteOTP(ctx context.Context, purpose, email string) {
	if service == nil || service.store == nil {
		return
	}
	baseCtx := ctx
	if baseCtx == nil {
		baseCtx = context.Background()
	}
	cleanupCtx, cancel := context.WithTimeout(context.WithoutCancel(baseCtx), _otpCleanupTimeout)
	defer cancel()
	if err := service.store.Delete(cleanupCtx, purpose, email); err != nil {
		service.log().WarnContext(ctx, "remove unsent otp failed", "error", err, "purpose", purpose)
	}
}

func (service *OTPService) requestCode(ctx context.Context, purpose, email string) error {
	if service == nil || service.store == nil || service.gateway == nil {
		return domain.ErrOTPUnavailable
	}
	code, err := service.generateOTP()
	if err != nil {
		return fmt.Errorf("generate otp: %w", err)
	}
	if err := service.store.Put(ctx, purpose, email, code, _otpLifetime); err != nil {
		service.log().WarnContext(ctx, "store otp failed", "error", err, "purpose", purpose)
		return fmt.Errorf("%w: store otp: %w", domain.ErrOTPUnavailable, err)
	}
	if err := service.gateway.Send(ctx, email, code); err != nil {
		service.deleteOTP(ctx, purpose, email)
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
		if errors.Is(err, domain.ErrUserNotFound) {
			return domain.User{}, domain.ErrInvalidCredentials
		}
		service.log().WarnContext(ctx, "find account for role-scoped operation failed", "error", err)
		return domain.User{}, domain.ErrOTPUnavailable
	}
	if account.ID == 0 || account.Role != role {
		return domain.User{}, domain.ErrInvalidCredentials
	}
	if !account.IsActive() {
		return domain.User{}, domain.ErrAccountSuspended
	}
	return account, nil
}

func (service *OTPService) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}

func (service *OTPService) generateOTP() (string, error) {
	if service != nil && service.generateCode != nil {
		return service.generateCode()
	}
	return generateOTP()
}

var _maxOTP = big.NewInt(1_000_000)

func GenerateOTP() (string, error) {
	return generateOTP()
}

func generateOTP() (string, error) {
	n, err := rand.Int(rand.Reader, _maxOTP)
	if err != nil {
		return "", fmt.Errorf("read otp randomness: %w", err)
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}
