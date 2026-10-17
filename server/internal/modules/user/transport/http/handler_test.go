package http

import (
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
)

func TestIsProfileNotFoundRecognizesNativeDatabaseErrors(t *testing.T) {
	if !isProfileNotFound(fmt.Errorf("load profile: %w", pgx.ErrNoRows)) {
		t.Fatal("expected wrapped PostgreSQL no-rows error to be classified as not found")
	}
	if isProfileNotFound(errors.New("profile query failed")) {
		t.Fatal("unexpected not-found classification for unrelated error")
	}
}

func TestPassengerMalformedIDReturnsBadRequest(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	handler := NewHandler(Dependencies{Verifier: manager})
	r := chi.NewRouter()
	r.Get("/passengers/{id}", handler.Profile)
	r.Put("/passengers/{id}", handler.ProfileUpdate)
	r.Get("/passengers/{id}/avatar", handler.Avatar)
	r.Post("/passengers/{id}/avatar", handler.AvatarUpload)
	r.Get("/passengers/{id}/notifications", handler.Notifications)
	r.Delete("/passengers/{id}/notifications/{notificationID}", handler.DeleteNotification)

	tests := []struct {
		method string
		path   string
	}{
		{method: http.MethodGet, path: "/passengers/invalid"},
		{method: http.MethodGet, path: "/passengers/-5"},
		{method: http.MethodGet, path: "/passengers/0"},
		{method: http.MethodPut, path: "/passengers/invalid"},
		{method: http.MethodGet, path: "/passengers/invalid/avatar"},
		{method: http.MethodGet, path: "/passengers/0/avatar"},
		{method: http.MethodPost, path: "/passengers/invalid/avatar"},
		{method: http.MethodGet, path: "/passengers/invalid/notifications"},
		{method: http.MethodDelete, path: "/passengers/invalid/notifications/1"},
	}

	for _, tt := range tests {
		t.Run(tt.method+" "+tt.path, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, tt.path, nil)
			req.Header.Set("Authorization", "Bearer "+token)
			rec := httptest.NewRecorder()
			r.ServeHTTP(rec, req)

			if rec.Code != http.StatusBadRequest {
				t.Fatalf("status = %d, want %d (body: %s)", rec.Code, http.StatusBadRequest, rec.Body.String())
			}
		})
	}
}

func TestPassengerForbiddenWhenAccessingOtherAccount(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	handler := NewHandler(Dependencies{Verifier: manager})
	r := chi.NewRouter()
	r.Get("/passengers/{id}", handler.Profile)
	r.Get("/passengers/{id}/avatar", handler.Avatar)
	r.Get("/passengers/{id}/notifications", handler.Notifications)

	tests := []struct {
		method string
		path   string
	}{
		{method: http.MethodGet, path: "/passengers/10"},
		{method: http.MethodGet, path: "/passengers/10/avatar"},
		{method: http.MethodGet, path: "/passengers/10/notifications"},
	}

	for _, tt := range tests {
		t.Run(tt.method+" "+tt.path, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, tt.path, nil)
			req.Header.Set("Authorization", "Bearer "+token)
			rec := httptest.NewRecorder()
			r.ServeHTTP(rec, req)

			if rec.Code != http.StatusForbidden {
				t.Fatalf("status = %d, want %d (body: %s)", rec.Code, http.StatusForbidden, rec.Body.String())
			}
		})
	}
}
