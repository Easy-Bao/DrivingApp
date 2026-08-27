package usecase

import (
	"context"
	"crypto/rand"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

const otpLifetime = 10 * time.Minute

type OTPService struct {
	users         domain.VerifiedUserRepository
	store         domain.OTPStore
	gateway       domain.OTPGateway
	tokens        domain.TokenIssuer
	sessions      domain.RefreshSessionStore
	pending       domain.PendingRegistrationStore
	registrations *RegisterService
}

func NewOTPService(users domain.VerifiedUserRepository, store domain.OTPStore, gateway domain.OTPGateway, tokens domain.TokenIssuer, sessions domain.RefreshSessionStore) *OTPService {
	return &OTPService{users: users, store: store, gateway: gateway, tokens: tokens, sessions: sessions}
}

func NewOTPServiceWithPending(users domain.VerifiedUserRepository, store domain.OTPStore, gateway domain.OTPGateway, tokens domain.TokenIssuer, pending domain.PendingRegistrationStore, registrations *RegisterService, sessions domain.RefreshSessionStore) *OTPService {
	return &OTPService{
		users:         users,
		store:         store,
		gateway:       gateway,
		tokens:        tokens,
		sessions:      sessions,
		pending:       pending,
		registrations: registrations,
	}
}

func (service *OTPService) RegisterPassenger(ctx context.Context, input RegisterInput) (domain.PendingRegistration, error) {
	if service.pending == nil || service.registrations == nil {
		return domain.PendingRegistration{}, domain.ErrOTPUnavailable
	}
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if account, err := service.users.FindByEmail(ctx, email); err == nil && account.ID != 0 {
		if account.Role != domain.Passenger || account.IsVerified {
			return domain.PendingRegistration{}, domain.ErrEmailTaken
		}
		if err := service.requestCode(ctx, "verification", account.Email); err != nil {
			return domain.PendingRegistration{}, err
		}
		return domain.PendingRegistration{Email: account.Email, Role: domain.Passenger}, nil
	}

	registration, err := service.registrations.PreparePassenger(ctx, input)
	if err != nil {
		return domain.PendingRegistration{}, err
	}
	if err := service.pending.Put(ctx, registration, otpLifetime); err != nil {
		return domain.PendingRegistration{}, err
	}
	if err := service.requestCode(ctx, "verification", registration.Email); err != nil {
		_ = service.pending.Delete(ctx, registration.Email)
		return domain.PendingRegistration{}, err
	}
	return registration, nil
}

func (service *OTPService) RequestVerification(ctx context.Context, email string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	if account, err := service.users.FindByEmail(ctx, email); err == nil && account.ID != 0 {
		if account.Role != domain.Passenger {
			return domain.ErrInvalidCredentials
		}
		return service.requestCode(ctx, "verification", account.Email)
	}
	if service.pending != nil {
		registration, err := service.pending.Get(ctx, email)
		if err == nil && registration.Role == domain.Passenger {
			return service.requestCode(ctx, "verification", registration.Email)
		}
	}
	return domain.ErrInvalidCredentials
}

func (service *OTPService) VerifyPassenger(ctx context.Context, email, code string) (domain.User, string, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if err := service.store.Consume(ctx, "verification", email, strings.TrimSpace(code)); err != nil {
		return domain.User{}, "", domain.ErrInvalidOTP
	}
	if account, err := service.users.FindByEmail(ctx, email); err == nil && account.ID != 0 {
		if account.Role != domain.Passenger {
			return domain.User{}, "", domain.ErrInvalidOTP
		}
		if err := service.users.MarkVerified(ctx, account.ID); err != nil {
			return domain.User{}, "", err
		}
		account.IsVerified = true
		token, err := issueToken(service.tokens, strconv.Itoa(account.ID), account.Role)
		return account, token, err
	}
	if service.pending == nil || service.registrations == nil {
		return domain.User{}, "", domain.ErrInvalidOTP
	}
	registration, err := service.pending.Get(ctx, email)
	if err != nil || registration.Role != domain.Passenger {
		return domain.User{}, "", domain.ErrInvalidOTP
	}
	account, token, err := service.registrations.CommitPendingPassenger(ctx, registration)
	if err != nil {
		return domain.User{}, "", err
	}
	if err := service.pending.Delete(ctx, registration.Email); err != nil {
		return domain.User{}, "", err
	}
	return account, token, nil
}

func (service *OTPService) IssueRefreshToken(ctx context.Context, account domain.User) (string, error) {
	return issueRefreshToken(ctx, service.sessions, strconv.Itoa(account.ID), account.Role)
}

func (service *OTPService) RequestPasswordReset(ctx context.Context, email string) error {
	return service.RequestPasswordResetForRole(ctx, email, domain.Passenger)
}

func (service *OTPService) ResetPassword(ctx context.Context, email, code, password string) error {
	return service.ResetPasswordForRole(ctx, email, code, password, domain.Passenger)
}

func (service *OTPService) RequestPasswordResetForRole(ctx context.Context, email string, role domain.Role) error {
	account, err := service.accountForRole(ctx, email, role)
	if err != nil {
		return err
	}
	return service.requestCode(ctx, "reset", account.Email)
}

func (service *OTPService) ResetPasswordForRole(ctx context.Context, email, code, password string, role domain.Role) error {
	account, err := service.accountForRole(ctx, email, role)
	if err != nil {
		return err
	}
	if len(password) < 8 || len([]byte(password)) > 72 {
		return domain.ErrInvalidCredentials
	}
	if err := service.store.Consume(ctx, "reset", account.Email, strings.TrimSpace(code)); err != nil {
		return domain.ErrInvalidOTP
	}
	if service.sessions == nil {
		return domain.ErrRefreshSessionUnavailable
	}
	if err := service.sessions.RevokeAll(ctx, account.ID, time.Now().UTC()); err != nil {
		return unavailableSessionError(err)
	}
	passwordHash, err := HashPasswordWithError(password)
	if err != nil {
		return err
	}
	return service.users.UpdatePassword(ctx, account.ID, passwordHash)
}

func (service *OTPService) requestCode(ctx context.Context, purpose, email string) error {
	code, err := generateOTP()
	if err != nil {
		return err
	}
	if err := service.store.Put(ctx, purpose, email, code, otpLifetime); err != nil {
		return err
	}
	if err := service.gateway.Send(ctx, email, code); err != nil {
		return domain.ErrOTPUnavailable
	}
	return nil
}

func (service *OTPService) account(ctx context.Context, email string) (domain.User, error) {
	return service.users.FindByEmail(ctx, strings.ToLower(strings.TrimSpace(email)))
}

func (service *OTPService) accountForRole(ctx context.Context, email string, role domain.Role) (domain.User, error) {
	account, err := service.account(ctx, email)
	if err != nil || account.Role != role {
		return domain.User{}, domain.ErrInvalidCredentials
	}
	return account, nil
}

func generateOTP() (string, error) {
	var bytes [4]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return "", err
	}
	value := uint32(bytes[0])<<24 | uint32(bytes[1])<<16 | uint32(bytes[2])<<8 | uint32(bytes[3])
	return fmt.Sprintf("%06d", value%1_000_000), nil
}
