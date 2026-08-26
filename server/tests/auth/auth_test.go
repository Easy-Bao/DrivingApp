package auth_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
)

type repository struct {
	users map[string]domain.User
	next  int
}

func (r *repository) Create(_ context.Context, account domain.User) (domain.User, error) {
	r.next++
	account.ID = r.next
	r.users[account.Email] = account
	return account, nil
}
func (r *repository) FindByEmail(_ context.Context, email string) (domain.User, error) {
	return r.users[email], nil
}
func (r *repository) FindByID(_ context.Context, id int) (domain.User, error) {
	for _, account := range r.users {
		if account.ID == id {
			return account, nil
		}
	}
	return domain.User{}, nil
}
func (r *repository) UpdatePassword(_ context.Context, id int, passwordHash string) error {
	for email, account := range r.users {
		if account.ID == id {
			account.PasswordHash = passwordHash
			r.users[email] = account
		}
	}
	return nil
}

type issuer struct{}

func (issuer) Issue(subject string) (string, error) { return "token:" + subject, nil }

func TestPassengerAndDriverRegistrationUseCases(t *testing.T) {
	repository := &repository{users: map[string]domain.User{}}
	service := usecase.NewRegisterService(repository, issuer{}, newTestRefreshSessionStore())
	passenger, passengerToken, err := service.Passenger(context.Background(), usecase.RegisterInput{Email: "passenger@example.test", Phone: "+639171234501", Name: "Passenger", Password: "secret-8"})
	if err != nil || passenger.Role != domain.Passenger || passengerToken != "token:1" {
		t.Fatalf("passenger registration = %#v, %q, %v", passenger, passengerToken, err)
	}
	driver, driverToken, err := service.Driver(context.Background(), usecase.RegisterInput{Email: "driver@example.test", Phone: "+639171234502", Name: "Driver", Password: "secret-8", VehicleType: "Sedan", PlateNumber: "ABC 123"})
	if err != nil || driver.Role != domain.Driver || driverToken != "token:2" {
		t.Fatalf("driver registration = %#v, %q, %v", driver, driverToken, err)
	}
}

func TestAuthenticationRejectsWrongPassword(t *testing.T) {
	repository := &repository{users: map[string]domain.User{}}
	sessions := newTestRefreshSessionStore()
	register := usecase.NewRegisterService(repository, issuer{}, sessions)
	_, _, _ = register.Passenger(context.Background(), usecase.RegisterInput{Email: "user@example.test", Phone: "+639171234503", Name: "User", Password: "secret-8"})
	authenticate := usecase.NewAuthenticateService(repository, issuer{}, sessions)
	if _, _, err := authenticate.Execute(context.Background(), "user@example.test", "wrong"); err != domain.ErrInvalidCredentials {
		t.Fatalf("expected invalid credentials, got %v", err)
	}
}

func TestRegistrationRejectsIncompleteRoleContracts(t *testing.T) {
	service := usecase.NewRegisterService(&repository{users: map[string]domain.User{}}, issuer{}, newTestRefreshSessionStore())

	if _, _, err := service.Passenger(context.Background(), usecase.RegisterInput{
		Email: "passenger@example.test", Name: "Passenger", Password: "secret-8",
	}); err != domain.ErrInvalidCredentials {
		t.Fatalf("missing passenger phone error = %v", err)
	}
	if _, _, err := service.Driver(context.Background(), usecase.RegisterInput{
		Email: "driver@example.test", Phone: "+639171234504", Name: "Driver", Password: "secret-8",
	}); err != domain.ErrInvalidCredentials {
		t.Fatalf("missing vehicle contract error = %v", err)
	}
}

func TestAuthenticationNormalizesEmailBeforeLookup(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"passenger@example.test": {
			ID:           9,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: usecase.HashPassword("secret-8"),
		},
	}}
	authenticate := usecase.NewAuthenticateService(repository, issuer{}, newTestRefreshSessionStore())

	if _, _, err := authenticate.Execute(context.Background(), " PASSENGER@EXAMPLE.TEST ", "secret-8"); err != nil {
		t.Fatalf("normalized login returned error: %v", err)
	}
}

func TestAuthenticationUpgradesLegacyPasswordHashAfterSuccessfulLogin(t *testing.T) {
	digest := sha256.Sum256([]byte("legacy-8"))
	legacyHash := hex.EncodeToString(digest[:])
	repository := &repository{users: map[string]domain.User{
		"legacy@example.test": {
			ID:           7,
			Email:        "legacy@example.test",
			Role:         domain.Passenger,
			PasswordHash: legacyHash,
		},
	}}
	authenticate := usecase.NewAuthenticateService(repository, issuer{}, newTestRefreshSessionStore())
	if _, _, err := authenticate.Execute(context.Background(), "legacy@example.test", "legacy-8"); err != nil {
		t.Fatalf("legacy authentication returned error: %v", err)
	}
	if repository.users["legacy@example.test"].PasswordHash == legacyHash {
		t.Fatal("expected successful login to replace the legacy hash")
	}
}
