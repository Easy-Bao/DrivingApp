package auth_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
)

func TestPassengerRegistrationCreatesAccountOnlyAfterOTP(t *testing.T) {
	repository := newPendingUserRepository()
	pending := &pendingRegistrationStore{}
	gateway := &otpGateway{}
	register := usecase.NewRegisterService(repository, otpIssuer{})
	service := usecase.NewOTPServiceWithPending(
		repository,
		&otpMemoryStore{values: map[string]string{}},
		gateway,
		otpIssuer{},
		pending,
		register,
	)

	registration, err := service.RegisterPassenger(context.Background(), usecase.RegisterInput{
		Email: "passenger@example.test", Name: "Passenger", Password: "secret-8",
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
	if _, err := pending.Get(context.Background(), registration.Email); !errors.Is(err, domain.ErrPendingRegistrationNotFound) {
		t.Fatalf("pending registration should be deleted, got %v", err)
	}
}

func TestRetryingUnverifiedPassengerRegistrationReplacesPendingData(t *testing.T) {
	repository := newPendingUserRepository()
	pending := &pendingRegistrationStore{}
	gateway := &otpGateway{}
	register := usecase.NewRegisterService(repository, otpIssuer{})
	service := usecase.NewOTPServiceWithPending(
		repository,
		&otpMemoryStore{values: map[string]string{}},
		gateway,
		otpIssuer{},
		pending,
		register,
	)

	_, err := service.RegisterPassenger(context.Background(), usecase.RegisterInput{
		Email: "passenger@example.test", Name: "First", Password: "first-password",
	})
	if err != nil {
		t.Fatalf("first registration: %v", err)
	}
	_, err = service.RegisterPassenger(context.Background(), usecase.RegisterInput{
		Email: " PASSENGER@example.test ", Name: "Second", Password: "second-password",
	})
	if err != nil {
		t.Fatalf("retry registration: %v", err)
	}

	stored, err := pending.Get(context.Background(), "passenger@example.test")
	if err != nil {
		t.Fatalf("get pending registration: %v", err)
	}
	if stored.Name != "Second" || stored.PasswordHash == usecase.HashPassword("first-password") {
		t.Fatalf("pending registration was not replaced: %#v", stored)
	}
	if len(repository.users) != 0 {
		t.Fatal("retrying an unverified registration must not create a database user")
	}
}

func TestPassengerRegistrationRejectsVerifiedEmail(t *testing.T) {
	repository := newPendingUserRepository()
	repository.users["passenger@example.test"] = domain.User{
		ID: 1, Email: "passenger@example.test", Role: domain.Passenger, IsVerified: true,
	}
	pending := &pendingRegistrationStore{}
	register := usecase.NewRegisterService(repository, otpIssuer{})
	service := usecase.NewOTPServiceWithPending(
		repository,
		&otpMemoryStore{values: map[string]string{}},
		&otpGateway{},
		otpIssuer{},
		pending,
		register,
	)

	if _, err := service.RegisterPassenger(context.Background(), usecase.RegisterInput{
		Email: "passenger@example.test", Password: "secret-8",
	}); !errors.Is(err, domain.ErrEmailTaken) {
		t.Fatalf("expected verified email conflict, got %v", err)
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
		return domain.User{}, errors.New("user not found")
	}
	return account, nil
}

func (repository *pendingUserRepository) FindByID(_ context.Context, id int) (domain.User, error) {
	for _, account := range repository.users {
		if account.ID == id {
			return account, nil
		}
	}
	return domain.User{}, errors.New("user not found")
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

type pendingRegistrationStore struct{ registration *domain.PendingRegistration }

func (store *pendingRegistrationStore) Put(_ context.Context, registration domain.PendingRegistration, _ time.Duration) error {
	copy := registration
	store.registration = &copy
	return nil
}

func (store *pendingRegistrationStore) Get(_ context.Context, email string) (domain.PendingRegistration, error) {
	if store.registration == nil || store.registration.Email != email {
		return domain.PendingRegistration{}, domain.ErrPendingRegistrationNotFound
	}
	return *store.registration, nil
}

func (store *pendingRegistrationStore) Delete(_ context.Context, _ string) error {
	store.registration = nil
	return nil
}
