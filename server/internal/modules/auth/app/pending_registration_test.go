package app_test

import (
	"context"
	"errors"
	"testing"
	"time"

	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
)

func TestPassengerRegistrationCreatesAccountOnlyAfterOTP(t *testing.T) {
	repository := newPendingUserRepository()
	pending := &pendingRegistrationStore{}
	gateway := &otpGateway{}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     otpIssuer{},
		Sessions:   sessions,
	})
	service := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:    repository,
			Store:    &otpMemoryStore{values: map[string]string{}},
			Gateway:  gateway,
			Tokens:   otpIssuer{},
			Sessions: sessions,
		},
		authapp.WithPendingRegistration(pending, register),
	)

	registration, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "passenger@example.test", Phone: "+639171234511", Name: "Passenger", Password: "secret-8",
	})
	if err != nil {
		t.Fatalf("register passenger: %v", err)
	}
	if registration.Email != "passenger@example.test" {
		t.Fatalf("pending email = %q", registration.Email)
	}
	if len(repository.users) != 0 {
		t.Fatal("unverified registration must not create a database user")
	}

	account, token, err := service.VerifyPassenger(context.Background(), registration.Email, gateway.sent)
	if err != nil {
		t.Fatalf("verify passenger: %v", err)
	}
	if account.ID != 1 || !account.IsVerified || token != "token:1" {
		t.Fatalf("verified account = %#v, token = %q", account, token)
	}
	_, err = pending.Get(
		context.Background(),
		registration.Email,
	)
	if !errors.Is(err, domain.ErrPendingRegistrationNotFound) {
		t.Fatalf("pending registration should be deleted, got %v", err)
	}
}

func TestRetryingUnverifiedPassengerRegistrationReplacesPendingData(t *testing.T) {
	repository := newPendingUserRepository()
	pending := &pendingRegistrationStore{}
	gateway := &otpGateway{}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     otpIssuer{},
		Sessions:   sessions,
	})
	service := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:    repository,
			Store:    &otpMemoryStore{values: map[string]string{}},
			Gateway:  gateway,
			Tokens:   otpIssuer{},
			Sessions: sessions,
		},
		authapp.WithPendingRegistration(pending, register),
	)

	_, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "passenger@example.test", Phone: "+639171234512", Name: "First", Password: "first-password",
	})
	if err != nil {
		t.Fatalf("first registration: %v", err)
	}
	_, err = service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: " PASSENGER@example.test ", Phone: "+639171234512", Name: "Second", Password: "second-password",
	})
	if err != nil {
		t.Fatalf("retry registration: %v", err)
	}

	stored, err := pending.Get(context.Background(), "passenger@example.test")
	if err != nil {
		t.Fatalf("get pending registration: %v", err)
	}
	if stored.Name != "Second" || stored.PasswordHash == testPasswordHash(t, "first-password") {
		t.Fatalf("pending registration was not replaced: %#v", stored)
	}
	if len(repository.users) != 0 {
		t.Fatal("retrying an unverified registration must not create a database user")
	}
}

func TestPassengerVerificationSucceedsWhenPendingCleanupFails(t *testing.T) {
	repository := newPendingUserRepository()
	pending := &pendingRegistrationStore{deleteErr: errors.New("temporary cleanup failure")}
	gateway := &otpGateway{}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     otpIssuer{},
		Sessions:   sessions,
	})
	service := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:    repository,
			Store:    &otpMemoryStore{values: map[string]string{}},
			Gateway:  gateway,
			Tokens:   otpIssuer{},
			Sessions: sessions,
		},
		authapp.WithPendingRegistration(pending, register),
	)

	registration, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "cleanup@example.test", Phone: "+639171234512", Name: "Passenger", Password: "secret-8",
	})
	if err != nil {
		t.Fatalf("register passenger: %v", err)
	}

	account, token, err := service.VerifyPassenger(context.Background(), registration.Email, gateway.sent)
	if err != nil {
		t.Fatalf("verify passenger after cleanup failure: %v", err)
	}
	if account.ID != 1 || token != "token:1" {
		t.Fatalf("verified account = %#v, token = %q", account, token)
	}
}

func TestPassengerRegistrationRejectsVerifiedEmail(t *testing.T) {
	repository := newPendingUserRepository()
	repository.users["passenger@example.test"] = domain.User{
		ID: 1, Email: "passenger@example.test", Role: domain.Passenger, IsVerified: true,
	}
	pending := &pendingRegistrationStore{}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     otpIssuer{},
		Sessions:   sessions,
	})
	service := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:    repository,
			Store:    &otpMemoryStore{values: map[string]string{}},
			Gateway:  &otpGateway{},
			Tokens:   otpIssuer{},
			Sessions: sessions,
		},
		authapp.WithPendingRegistration(pending, register),
	)

	if _, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "passenger@example.test", Phone: "+639171234513", Name: "Passenger", Password: "secret-8",
	}); !errors.Is(err, domain.ErrEmailTaken) {
		t.Fatalf("expected verified email conflict, got %v", err)
	}
}

type failingOTPGateway struct {
	sent string
	err  error
}

func (gateway *failingOTPGateway) Send(_ context.Context, _, code string) error {
	if gateway.err != nil {
		return gateway.err
	}
	gateway.sent = code
	return nil
}

func TestRegisterPassengerRestoresPreviousPendingAndInvalidatesPriorOTPOnSendFailure(t *testing.T) {
	repository := newPendingUserRepository()
	pending := &pendingRegistrationStore{}
	gateway := &failingOTPGateway{}
	store := &otpMemoryStore{values: map[string]string{}}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     otpIssuer{},
		Sessions:   sessions,
	})
	codes := []string{"111111", "222222"}
	codeIndex := 0
	service := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:    repository,
			Store:    store,
			Gateway:  gateway,
			Tokens:   otpIssuer{},
			Sessions: sessions,
			GenerateCode: func() (string, error) {
				c := codes[codeIndex]
				codeIndex++
				return c, nil
			},
		},
		authapp.WithPendingRegistration(pending, register),
	)

	if _, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "alice@example.test", Phone: "+639171234511", Name: "Alice", Password: "alice-password",
	}); err != nil {
		t.Fatalf("initial registration: %v", err)
	}
	firstCode := gateway.sent

	gateway.err = errors.New("smtp unavailable")
	_, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "alice@example.test", Phone: "+639171234599", Name: "Mallory", Password: "mallory-password",
	})
	if !errors.Is(err, domain.ErrOTPUnavailable) {
		t.Fatalf("failed retry error = %v, want ErrOTPUnavailable", err)
	}

	// Previous pending registration must be preserved (not deleted or replaced by Mallory's data).
	stored, err := pending.Get(context.Background(), "alice@example.test")
	if err != nil {
		t.Fatalf("previous pending registration was lost: %v", err)
	}
	if stored.Name != "Alice" {
		t.Fatalf("stored pending name = %q, want Alice", stored.Name)
	}
	// Earlier OTP was invalidated before any overwrite attempt.
	if _, _, err := service.VerifyPassenger(context.Background(), "alice@example.test", firstCode); !errors.Is(err, domain.ErrInvalidOTP) {
		t.Fatalf("expected prior OTP to be invalidated, got %v", err)
	}
}

func TestRequestVerificationRefreshesPendingRegistrationTTL(t *testing.T) {
	repository := newPendingUserRepository()
	pending := &pendingRegistrationStore{}
	gateway := &otpGateway{}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     otpIssuer{},
		Sessions:   sessions,
	})
	service := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:    repository,
			Store:    &otpMemoryStore{values: map[string]string{}},
			Gateway:  gateway,
			Tokens:   otpIssuer{},
			Sessions: sessions,
		},
		authapp.WithPendingRegistration(pending, register),
	)

	if _, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "pending@example.test", Phone: "+639171234514", Name: "Pending", Password: "secret-8",
	}); err != nil {
		t.Fatalf("register passenger: %v", err)
	}
	beforePuts := pending.putCount
	if err := service.RequestVerification(context.Background(), "pending@example.test"); err != nil {
		t.Fatalf("RequestVerification() error = %v", err)
	}
	if pending.putCount != beforePuts+1 {
		t.Fatalf("pending.Put call count = %d, want %d (TTL refresh)", pending.putCount, beforePuts+1)
	}
}

func TestRegisterPassengerRejectsSuspendedUnverifiedAccount(t *testing.T) {
	repository := newPendingUserRepository()
	repository.users["suspended@example.test"] = domain.User{
		ID:            2,
		Email:         "suspended@example.test",
		Role:          domain.Passenger,
		IsVerified:    false,
		AccountStatus: "suspended",
	}
	gateway := &otpGateway{}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     otpIssuer{},
		Sessions:   sessions,
	})
	service := authapp.NewOTPService(
		authapp.OTPDependencies{
			Users:    repository,
			Store:    &otpMemoryStore{values: map[string]string{}},
			Gateway:  gateway,
			Tokens:   otpIssuer{},
			Sessions: sessions,
		},
		authapp.WithPendingRegistration(&pendingRegistrationStore{}, register),
	)

	if _, err := service.RegisterPassenger(context.Background(), authapp.RegisterInput{
		Email: "suspended@example.test", Phone: "+639171234515", Name: "Suspended", Password: "secret-8",
	}); !errors.Is(err, domain.ErrEmailTaken) {
		t.Fatalf("expected ErrEmailTaken for suspended unverified account, got %v", err)
	}
	if gateway.sent != "" {
		t.Fatal("verification OTP should not be sent for a suspended account")
	}
}

type pendingUserRepository struct {
	users map[string]domain.User
	next  int
}

func newPendingUserRepository() *pendingUserRepository {
	return &pendingUserRepository{users: map[string]domain.User{}}
}

func (repository *pendingUserRepository) Create(_ context.Context, account domain.User) (domain.User, error) {
	repository.next++
	account.ID = repository.next
	repository.users[account.Email] = account
	return account, nil
}

func (repository *pendingUserRepository) FindByEmail(_ context.Context, email string) (domain.User, error) {
	account, ok := repository.users[email]
	if !ok {
		return domain.User{}, domain.ErrUserNotFound
	}
	return account, nil
}

func (repository *pendingUserRepository) FindByID(_ context.Context, id int) (domain.User, error) {
	for _, account := range repository.users {
		if account.ID == id {
			return account, nil
		}
	}
	return domain.User{}, domain.ErrUserNotFound
}

func (repository *pendingUserRepository) UpdatePassword(_ context.Context, id int, passwordHash string) error {
	for email, account := range repository.users {
		if account.ID == id {
			account.PasswordHash = passwordHash
			repository.users[email] = account
		}
	}
	return nil
}

func (repository *pendingUserRepository) MarkVerified(_ context.Context, id int) error {
	for email, account := range repository.users {
		if account.ID == id {
			account.IsVerified = true
			repository.users[email] = account
		}
	}
	return nil
}

type pendingRegistrationStore struct {
	registration *domain.PendingRegistration
	deleteErr    error
	putCount     int
}

func (store *pendingRegistrationStore) Put(
	_ context.Context,
	registration domain.PendingRegistration,
	_ time.Duration,
) error {
	copy := registration
	store.registration = &copy
	store.putCount++
	return nil
}

func (store *pendingRegistrationStore) Get(_ context.Context, email string) (domain.PendingRegistration, error) {
	if store.registration == nil || store.registration.Email != email {
		return domain.PendingRegistration{}, domain.ErrPendingRegistrationNotFound
	}
	return *store.registration, nil
}

func (store *pendingRegistrationStore) Delete(_ context.Context, _ string) error {
	if store.deleteErr != nil {
		return store.deleteErr
	}
	store.registration = nil
	return nil
}

func (repository *pendingUserRepository) UpgradePasswordHash(_ context.Context, id int, expectedHash, passwordHash string) (bool, error) {
	return false, nil
}
