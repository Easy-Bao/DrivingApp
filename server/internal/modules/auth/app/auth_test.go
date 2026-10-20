package app_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"testing"

	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
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
	service := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     issuer{},
		Sessions:   newTestRefreshSessionStore(),
	})
	passenger, passengerToken, err := service.Passenger(
		context.Background(),
		authapp.RegisterInput{
			Email:    "passenger@example.test",
			Phone:    "+639171234501",
			Name:     "Passenger",
			Password: "secret-8",
		},
	)
	if err != nil || passenger.Role != domain.Passenger || passengerToken != "token:1" {
		t.Fatalf("passenger registration = %#v, %q, %v", passenger, passengerToken, err)
	}
	driver, driverToken, err := service.Driver(
		context.Background(),
		authapp.RegisterInput{
			Email:       "driver@example.test",
			Phone:       "+639171234502",
			Name:        "Driver",
			Password:    "secret-8",
			VehicleType: "Sedan",
			PlateNumber: "ABC 123",
		},
	)
	if err != nil || driver.Role != domain.Driver || driverToken != "token:2" {
		t.Fatalf("driver registration = %#v, %q, %v", driver, driverToken, err)
	}
}

func TestAuthenticationRejectsWrongPassword(t *testing.T) {
	repository := &repository{users: map[string]domain.User{}}
	sessions := newTestRefreshSessionStore()
	register := newTestRegisterService(authapp.RegisterDependencies{
		Repository: repository,
		Tokens:     issuer{},
		Sessions:   sessions,
	})
	_, _, _ = register.Passenger(
		context.Background(),
		authapp.RegisterInput{
			Email:    "user@example.test",
			Phone:    "+639171234503",
			Name:     "User",
			Password: "secret-8",
		},
	)
	authenticate := newTestAuthenticateService(authapp.AuthenticateDependencies{
		Repository: repository,
		Tokens:     issuer{},
		Sessions:   sessions,
	})
	_, _, err := authenticate.Execute(
		context.Background(),
		"user@example.test",
		"wrong",
	)
	if !errors.Is(err, domain.ErrInvalidCredentials) {
		t.Fatalf("expected invalid credentials, got %v", err)
	}
}

func TestRegistrationRejectsIncompleteRoleContracts(t *testing.T) {
	service := newTestRegisterService(authapp.RegisterDependencies{
		Repository: &repository{users: map[string]domain.User{}},
		Tokens:     issuer{},
		Sessions:   newTestRefreshSessionStore(),
	})

	if _, _, err := service.Passenger(context.Background(), authapp.RegisterInput{
		Email: "passenger@example.test", Name: "Passenger", Password: "secret-8",
	}); !errors.Is(err, domain.ErrInvalidCredentials) {
		t.Fatalf("missing passenger phone error = %v", err)
	}
	if _, _, err := service.Driver(context.Background(), authapp.RegisterInput{
		Email: "driver@example.test", Phone: "+639171234504", Name: "Driver", Password: "secret-8",
	}); !errors.Is(err, domain.ErrInvalidCredentials) {
		t.Fatalf("missing vehicle contract error = %v", err)
	}
}

func TestAuthenticationNormalizesEmailBeforeLookup(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"passenger@example.test": {
			ID:           9,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: testPasswordHash(t, "secret-8"),
		},
	}}
	authenticate := newTestAuthenticateService(authapp.AuthenticateDependencies{
		Repository: repository,
		Tokens:     issuer{},
		Sessions:   newTestRefreshSessionStore(),
	})

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
	authenticate := newTestAuthenticateService(authapp.AuthenticateDependencies{
		Repository: repository,
		Tokens:     issuer{},
		Sessions:   newTestRefreshSessionStore(),
	})
	if _, _, err := authenticate.Execute(context.Background(), "legacy@example.test", "legacy-8"); err != nil {
		t.Fatalf("legacy authentication returned error: %v", err)
	}
	if repository.users["legacy@example.test"].PasswordHash == legacyHash {
		t.Fatal("expected successful login to replace the legacy hash")
	}
}

// resetDuringLoginRepository simulates a password reset finishing between the
// login's credential check and its legacy hash upgrade.
type resetDuringLoginRepository struct {
	*repository
	resetHash string
}

func (r *resetDuringLoginRepository) UpgradePasswordHash(ctx context.Context, id int, expectedHash, passwordHash string) (bool, error) {
	if err := r.repository.UpdatePassword(ctx, id, r.resetHash); err != nil {
		return false, err
	}
	return r.repository.UpgradePasswordHash(ctx, id, expectedHash, passwordHash)
}

func TestConcurrentPasswordResetBeatsLegacyUpgradeAndOldPasswordSession(t *testing.T) {
	digest := sha256.Sum256([]byte("legacy-8"))
	legacyHash := hex.EncodeToString(digest[:])
	base := &repository{users: map[string]domain.User{
		"legacy@example.test": {
			ID:           7,
			Email:        "legacy@example.test",
			Role:         domain.Passenger,
			PasswordHash: legacyHash,
		},
	}}
	const resetHash = "hash-from-password-reset"
	authenticate := newTestAuthenticateService(authapp.AuthenticateDependencies{
		Repository: &resetDuringLoginRepository{repository: base, resetHash: resetHash},
		Tokens:     issuer{},
		Sessions:   newTestRefreshSessionStore(),
	})

	// The login verified the superseded password, so it must not keep a
	// session once the reset has replaced it.
	_, _, err := authenticate.Execute(context.Background(), "legacy@example.test", "legacy-8")
	if !errors.Is(err, domain.ErrInvalidCredentials) {
		t.Fatalf("Execute() error = %v, want invalid credentials", err)
	}
	if got := base.users["legacy@example.test"].PasswordHash; got != resetHash {
		t.Fatalf("password hash = %q, want the reset hash %q", got, resetHash)
	}
}

func TestAuthenticationRejectsSuspendedAccount(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"suspended@example.test": {
			ID:            10,
			Email:         "suspended@example.test",
			Role:          domain.Passenger,
			PasswordHash:  testPasswordHash(t, "secret-8"),
			AccountStatus: "suspended",
		},
	}}
	authenticate := newTestAuthenticateService(authapp.AuthenticateDependencies{
		Repository: repository,
		Tokens:     issuer{},
		Sessions:   newTestRefreshSessionStore(),
	})
	if _, _, err := authenticate.Execute(context.Background(), "suspended@example.test", "secret-8"); !errors.Is(err, domain.ErrAccountSuspended) {
		t.Fatalf("expected ErrAccountSuspended, got %v", err)
	}
}

func (r *repository) UpgradePasswordHash(_ context.Context, id int, expectedHash, passwordHash string) (bool, error) {
	for email, account := range r.users {
		if account.ID == id && account.PasswordHash == expectedHash {
			account.PasswordHash = passwordHash
			r.users[email] = account
			return true, nil
		}
	}
	return false, nil
}
