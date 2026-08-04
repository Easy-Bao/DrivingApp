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
	users   domain.VerifiedUserRepository
	store   domain.OTPStore
	gateway domain.OTPGateway
	tokens  domain.TokenIssuer
}

func NewOTPService(users domain.VerifiedUserRepository, store domain.OTPStore, gateway domain.OTPGateway, tokens domain.TokenIssuer) *OTPService {
	return &OTPService{users: users, store: store, gateway: gateway, tokens: tokens}
}

func (service *OTPService) RequestVerification(ctx context.Context, email string) error {
	return service.request(ctx, "verification", email)
}

func (service *OTPService) VerifyPassenger(ctx context.Context, email, code string) (domain.User, string, error) {
	account, err := service.account(ctx, email)
	if err != nil || account.Role != domain.Passenger {
		return domain.User{}, "", domain.ErrInvalidOTP
	}
	if err := service.store.Consume(ctx, "verification", account.Email, strings.TrimSpace(code)); err != nil {
		return domain.User{}, "", domain.ErrInvalidOTP
	}
	if err := service.users.MarkVerified(ctx, account.ID); err != nil {
		return domain.User{}, "", err
	}
	account.IsVerified = true
	token, err := service.tokens.Issue(strconv.Itoa(account.ID))
	return account, token, err
}

func (service *OTPService) RequestPasswordReset(ctx context.Context, email string) error {
	return service.request(ctx, "reset", email)
}

func (service *OTPService) ResetPassword(ctx context.Context, email, code, password string) error {
	account, err := service.account(ctx, email)
	if err != nil {
		return domain.ErrInvalidCredentials
	}
	if strings.TrimSpace(password) == "" {
		return domain.ErrInvalidCredentials
	}
	if err := service.store.Consume(ctx, "reset", account.Email, strings.TrimSpace(code)); err != nil {
		return domain.ErrInvalidOTP
	}
	return service.users.UpdatePassword(ctx, account.ID, HashPassword(password))
}

func (service *OTPService) request(ctx context.Context, purpose, email string) error {
	account, err := service.account(ctx, email)
	if err != nil {
		return domain.ErrInvalidCredentials
	}
	code, err := generateOTP()
	if err != nil {
		return err
	}
	if err := service.store.Put(ctx, purpose, account.Email, code, otpLifetime); err != nil {
		return err
	}
	if err := service.gateway.Send(ctx, account.Email, code); err != nil {
		return domain.ErrOTPUnavailable
	}
	return nil
}

func (service *OTPService) account(ctx context.Context, email string) (domain.User, error) {
	return service.users.FindByEmail(ctx, strings.ToLower(strings.TrimSpace(email)))
}

func generateOTP() (string, error) {
	var bytes [4]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return "", err
	}
	value := uint32(bytes[0])<<24 | uint32(bytes[1])<<16 | uint32(bytes[2])<<8 | uint32(bytes[3])
	return fmt.Sprintf("%06d", value%1_000_000), nil
}
