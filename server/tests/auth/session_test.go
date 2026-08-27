package auth_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

func TestRefreshSessionsAreOpaqueAndRotateOnce(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"passenger@example.test": {
			ID:           7,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: usecase.HashPassword("secret-8"),
		},
	}}
	sessions := newTestRefreshSessionStore()
	service := usecase.NewAuthenticateService(repository, security.NewTokenManager("session-test-secret"), sessions)

	_, first, err := service.ExecuteSession(context.Background(), "passenger@example.test", "secret-8")
	if err != nil {
		t.Fatalf("issue session: %v", err)
	}
	if strings.Count(first.RefreshToken, ".") == 2 {
		t.Fatal("refresh token must not be a JWT")
	}

	second, err := service.Refresh(context.Background(), first.RefreshToken)
	if err != nil {
		t.Fatalf("rotate session: %v", err)
	}
	_, err = service.Refresh(context.Background(), first.RefreshToken)
	if !errors.Is(err, domain.ErrInvalidRefreshToken) {
		t.Fatalf("old refresh token error = %v, want invalid refresh token", err)
	}

	rotated, err := service.Refresh(context.Background(), second.RefreshToken)
	if err != nil {
		t.Fatalf("refresh replacement session: %v", err)
	}
	if rotated.RefreshToken == "" {
		t.Fatal("replacement refresh token is empty")
	}
}

func TestLogoutRevokesRefreshSession(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"passenger@example.test": {
			ID:           8,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: usecase.HashPassword("secret-8"),
		},
	}}
	sessions := newTestRefreshSessionStore()
	service := usecase.NewAuthenticateService(repository, security.NewTokenManager("logout-test-secret"), sessions)

	_, issued, err := service.ExecuteSession(context.Background(), "passenger@example.test", "secret-8")
	if err != nil {
		t.Fatalf("issue session: %v", err)
	}
	if err := service.Logout(context.Background(), issued.RefreshToken); err != nil {
		t.Fatalf("logout: %v", err)
	}
	if _, err := service.Refresh(context.Background(), issued.RefreshToken); !errors.Is(err, domain.ErrInvalidRefreshToken) {
		t.Fatalf("revoked refresh token error = %v, want invalid refresh token", err)
	}
}
