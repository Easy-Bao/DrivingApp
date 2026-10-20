package app_test

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
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
		return domain.ErrInvalidOTP
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
	service := authapp.NewOTPService(authapp.OTPDependencies{
		Users:    repository,
		Store:    store,
		Gateway:  gateway,
		Tokens:   otpIssuer{},
		Sessions: newTestRefreshSessionStore(),
	})

	if err := service.RequestVerification(context.Background(), repository.account.Email); err != nil {
		t.Fatalf("request verification: %v", err)
	}
	account, token, err := service.VerifyPassenger(context.Background(), repository.account.Email, gateway.sent)
	if err != nil || token != "token:7" || !repository.marked || !account.IsVerified {
		t.Fatalf("verify result = %#v, %q, marked=%t, err=%v", account, token, repository.marked, err)
	}
	_, _, err = service.VerifyPassenger(
		context.Background(),
		repository.account.Email,
		gateway.sent,
	)
	if !errors.Is(err, domain.ErrInvalidOTP) {
		t.Fatalf("expected consumed otp to fail, got %v", err)
	}
}

func TestDriverCannotUsePassengerVerificationOTP(t *testing.T) {
	repository := &otpRepository{account: domain.User{ID: 8, Email: "driver@example.test", Role: domain.Driver}}
	service := authapp.NewOTPService(authapp.OTPDependencies{
		Users:    repository,
		Store:    &otpMemoryStore{values: map[string]string{}},
		Gateway:  &otpGateway{},
		Tokens:   otpIssuer{},
		Sessions: newTestRefreshSessionStore(),
	})
	_, _, err := service.VerifyPassenger(
		context.Background(),
		repository.account.Email,
		"123456",
	)
	if !errors.Is(err, domain.ErrInvalidOTP) {
		t.Fatalf("expected passenger-only verification to reject driver, got %v", err)
	}
}

func TestPasswordResetIsScopedToTheAccountRole(t *testing.T) {
	repository := &otpRepository{account: domain.User{ID: 8, Email: "driver@example.test", Role: domain.Driver}}
	store := &otpMemoryStore{values: map[string]string{}}
	gateway := &otpGateway{}
	service := authapp.NewOTPService(authapp.OTPDependencies{
		Users:    repository,
		Store:    store,
		Gateway:  gateway,
		Tokens:   otpIssuer{},
		Sessions: newTestRefreshSessionStore(),
	})

	err := service.RequestPasswordReset(
		context.Background(),
		repository.account.Email,
	)
	if err != nil {
		t.Fatalf("expected silent success for enumeration protection, got %v", err)
	}
	if gateway.sent != "" {
		t.Fatal("expected no OTP code sent when role does not match")
	}

	err = service.RequestPasswordResetForRole(
		context.Background(),
		repository.account.Email,
		domain.Driver,
	)
	if err != nil {
		t.Fatalf("driver reset request failed: %v", err)
	}
	if gateway.sent == "" {
		t.Fatal("expected OTP code sent for matching role")
	}
}

func TestRequestVerificationAntiEnumeration(t *testing.T) {
	repository := &otpRepository{account: domain.User{}}
	gateway := &otpGateway{}
	service := authapp.NewOTPService(authapp.OTPDependencies{
		Users:    repository,
		Store:    &otpMemoryStore{values: map[string]string{}},
		Gateway:  gateway,
		Tokens:   otpIssuer{},
		Sessions: newTestRefreshSessionStore(),
	})
	err := service.RequestVerification(context.Background(), "nonexistent@example.test")
	if err != nil {
		t.Fatalf("expected nil for non-existent account, got %v", err)
	}
	if gateway.sent != "" {
		t.Fatal("expected no OTP sent for non-existent account")
	}
}

func TestSuspendedPassengerCannotUseVerificationOTP(t *testing.T) {
	repository := &otpRepository{account: domain.User{
		ID: 7, Email: "p@example.test", Role: domain.Passenger, AccountStatus: "suspended",
	}}
	gateway := &otpGateway{}
	store := &otpMemoryStore{values: map[string]string{}}
	service := authapp.NewOTPService(authapp.OTPDependencies{
		Users:    repository,
		Store:    store,
		Gateway:  gateway,
		Tokens:   otpIssuer{},
		Sessions: newTestRefreshSessionStore(),
	})

	if err := service.RequestVerification(context.Background(), "p@example.test"); err != nil {
		t.Fatalf("RequestVerification() error = %v, want nil", err)
	}
	if gateway.sent != "" {
		t.Fatal("verification code was sent to a suspended account")
	}

	// A code issued before the suspension must not yield credentials.
	store.values["verification:p@example.test"] = "123456"
	_, token, err := service.VerifyPassenger(context.Background(), "p@example.test", "123456")
	if !errors.Is(err, domain.ErrAccountSuspended) || token != "" {
		t.Fatalf("VerifyPassenger() = token %q, error %v; want suspended error", token, err)
	}
	if repository.marked {
		t.Fatal("suspended account was marked verified")
	}
}

func (repository *otpRepository) UpgradePasswordHash(_ context.Context, id int, expectedHash, passwordHash string) (bool, error) {
	return false, nil
}
