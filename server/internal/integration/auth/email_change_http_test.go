//go:build integration

package auth_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/verification"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type emailChangeGateway struct {
	recipient string
	code      string
}

func (gateway *emailChangeGateway) Send(_ context.Context, recipient, code string) error {
	gateway.recipient = recipient
	gateway.code = code
	return nil
}

type emailChangeNotifier struct {
	previousEmail string
	newEmail      string
}

func (notifier *emailChangeNotifier) NotifyEmailChanged(_ context.Context, previousEmail, newEmail string) error {
	notifier.previousEmail = previousEmail
	notifier.newEmail = newEmail
	return nil
}

func (repository *repository) UpdateEmail(
	_ context.Context,
	userID int,
	expectedEmail string,
	newEmail string,
) error {
	for currentEmail, account := range repository.users {
		if account.Email == newEmail && account.ID != userID {
			return domain.ErrEmailTaken
		}
		if account.ID != userID {
			continue
		}
		if account.Email != expectedEmail {
			return domain.ErrEmailChangeStale
		}
		delete(repository.users, currentEmail)
		account.Email = newEmail
		account.IsVerified = true
		repository.users[newEmail] = account
		return nil
	}
	return domain.ErrEmailChangeStale
}

func TestEmailChangeHTTPRequiresAuthenticationAndConfirmsNewAddress(t *testing.T) {
	accounts := &repository{users: map[string]domain.User{
		"old@example.test": {
			ID:           42,
			Email:        "old@example.test",
			Role:         domain.Passenger,
			PasswordHash: testPasswordHash(t, "current-password"),
			IsVerified:   true,
		},
	}}
	manager := security.NewTokenManager("email-change-http-test-secret")
	token, err := manager.IssueWithRole("42", string(domain.Passenger))
	if err != nil {
		t.Fatal(err)
	}
	store := &resetOTPStore{}
	gateway := &emailChangeGateway{}
	notifier := &emailChangeNotifier{}
	otp := verification.NewOTPService(verification.Dependencies{
		Users:         accounts,
		EmailChanges:  accounts,
		EmailNotifier: notifier,
		Store:         store,
		Gateway:       gateway,
	})
	router := chi.NewRouter()
	authhttp.NewRouter(
		authhttp.RouterDependencies{OTP: otp, Verifier: manager},
		authhttp.WithOTPAttemptStore(middleware.NewMemoryCounterStore()),
	).RegisterRoutes(router)

	unauthenticated := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/users/me/email/request",
		strings.NewReader(`{"current_password":"current-password","email":"new@example.test"}`),
	)
	unauthenticatedResponse := httptest.NewRecorder()
	router.ServeHTTP(unauthenticatedResponse, unauthenticated)
	if unauthenticatedResponse.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated request status = %d, want %d", unauthenticatedResponse.Code, http.StatusUnauthorized)
	}

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/users/me/email/request",
		strings.NewReader(`{"current_password":"wrong-password","email":"new@example.test"}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusUnauthorized || gateway.code != "" {
		t.Fatalf("wrong-password response = %d, code sent = %t", response.Code, gateway.code != "")
	}

	request = httptest.NewRequest(
		http.MethodPost,
		"/api/v1/users/me/email/request",
		strings.NewReader(`{"current_password":"current-password","email":" New@Example.Test "}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response = httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusAccepted || gateway.recipient != "new@example.test" || gateway.code == "" {
		t.Fatalf("email request response = %d, recipient = %q, code sent = %t", response.Code, gateway.recipient, gateway.code != "")
	}
	if accounts.users["old@example.test"].Email != "old@example.test" {
		t.Fatal("email changed before OTP confirmation")
	}

	request = httptest.NewRequest(
		http.MethodPost,
		"/api/v1/users/me/email/confirm",
		strings.NewReader(`{"email":"new@example.test","code":"`+gateway.code+`"}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response = httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent {
		t.Fatalf("confirmation status = %d, body = %s", response.Code, response.Body.String())
	}
	account, exists := accounts.users["new@example.test"]
	if !exists || account.Email != "new@example.test" || !account.IsVerified {
		t.Fatalf("updated account = %#v, exists = %t", account, exists)
	}
	if notifier.previousEmail != "old@example.test" || notifier.newEmail != "new@example.test" {
		t.Fatalf("notification = %#v", notifier)
	}
}
