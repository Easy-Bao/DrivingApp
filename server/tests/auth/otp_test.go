package auth_test

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
)

type otpRepository struct {
	account domain.User
	marked  bool
}

func (repository *otpRepository) Create(context.Context, domain.User) (domain.User, error) {
	return repository.account, nil
}
func (repository *otpRepository) FindByEmail(context.Context, string) (domain.User, error) {
	return repository.account, nil
}
func (repository *otpRepository) FindByID(context.Context, int) (domain.User, error) {
	return repository.account, nil
}
func (repository *otpRepository) UpdatePassword(context.Context, int, string) error { return nil }
func (repository *otpRepository) MarkVerified(context.Context, int) error {
	repository.marked = true
	return nil
}

type otpMemoryStore struct{ values map[string]string }

func (store *otpMemoryStore) Put(_ context.Context, purpose, email, code string, _ time.Duration) error {
	store.values[purpose+":"+strings.ToLower(email)] = code
	return nil
}
func (store *otpMemoryStore) Consume(_ context.Context, purpose, email, code string) error {
	key := purpose + ":" + strings.ToLower(email)
	if store.values[key] != code {
		return fmt.Errorf("invalid otp")
	}
	delete(store.values, key)
	return nil
}

type otpGateway struct{ sent string }

func (gateway *otpGateway) Send(_ context.Context, _, code string) error {
	gateway.sent = code
	return nil
}

type otpIssuer struct{}

func (otpIssuer) Issue(subject string) (string, error) { return "token:" + subject, nil }

func TestPassengerOTPVerifiesAndConsumesCode(t *testing.T) {
	repository := &otpRepository{account: domain.User{ID: 7, Email: "passenger@example.test", Role: domain.Passenger}}
	store := &otpMemoryStore{values: map[string]string{}}
	gateway := &otpGateway{}
	service := usecase.NewOTPService(repository, store, gateway, otpIssuer{}, newTestRefreshSessionStore())

	if err := service.RequestVerification(context.Background(), repository.account.Email); err != nil {
		t.Fatalf("request verification: %v", err)
	}
	account, token, err := service.VerifyPassenger(context.Background(), repository.account.Email, gateway.sent)
	if err != nil || token != "token:7" || !repository.marked || !account.IsVerified {
		t.Fatalf("verify result = %#v, %q, marked=%t, err=%v", account, token, repository.marked, err)
	}
	if _, _, err := service.VerifyPassenger(context.Background(), repository.account.Email, gateway.sent); err != domain.ErrInvalidOTP {
		t.Fatalf("expected consumed otp to fail, got %v", err)
	}
}

func TestDriverCannotUsePassengerVerificationOTP(t *testing.T) {
	repository := &otpRepository{account: domain.User{ID: 8, Email: "driver@example.test", Role: domain.Driver}}
	service := usecase.NewOTPService(repository, &otpMemoryStore{values: map[string]string{}}, &otpGateway{}, otpIssuer{}, newTestRefreshSessionStore())
	if _, _, err := service.VerifyPassenger(context.Background(), repository.account.Email, "123456"); err != domain.ErrInvalidOTP {
		t.Fatalf("expected passenger-only verification to reject driver, got %v", err)
	}
}

func TestPasswordResetIsScopedToTheAccountRole(t *testing.T) {
	repository := &otpRepository{account: domain.User{ID: 8, Email: "driver@example.test", Role: domain.Driver}}
	store := &otpMemoryStore{values: map[string]string{}}
	service := usecase.NewOTPService(repository, store, &otpGateway{}, otpIssuer{}, newTestRefreshSessionStore())

	if err := service.RequestPasswordReset(context.Background(), repository.account.Email); err != domain.ErrInvalidCredentials {
		t.Fatalf("expected passenger reset route to reject driver account, got %v", err)
	}
	if err := service.RequestPasswordResetForRole(context.Background(), repository.account.Email, domain.Driver); err != nil {
		t.Fatalf("driver reset request failed: %v", err)
	}
}
