package auth_test

import (
	"context"
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
	service := usecase.NewRegisterService(repository, issuer{})
	passenger, passengerToken, err := service.Passenger(context.Background(), usecase.RegisterInput{Email: "passenger@example.test", Password: "secret"})
	if err != nil || passenger.Role != domain.Passenger || passengerToken != "token:1" {
		t.Fatalf("passenger registration = %#v, %q, %v", passenger, passengerToken, err)
	}
	driver, driverToken, err := service.Driver(context.Background(), usecase.RegisterInput{Email: "driver@example.test", Password: "secret"})
	if err != nil || driver.Role != domain.Driver || driverToken != "token:2" {
		t.Fatalf("driver registration = %#v, %q, %v", driver, driverToken, err)
	}
}

func TestAuthenticationRejectsWrongPassword(t *testing.T) {
	repository := &repository{users: map[string]domain.User{}}
	register := usecase.NewRegisterService(repository, issuer{})
	_, _, _ = register.Passenger(context.Background(), usecase.RegisterInput{Email: "user@example.test", Password: "secret"})
	authenticate := usecase.NewAuthenticateService(repository, issuer{})
	if _, _, err := authenticate.Execute(context.Background(), "user@example.test", "wrong"); err != domain.ErrInvalidCredentials {
		t.Fatalf("expected invalid credentials, got %v", err)
	}
}
