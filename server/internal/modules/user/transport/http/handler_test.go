package http

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

func TestWriteProfileReadErrorMapsDomainAndFallbackErrors(t *testing.T) {
	notFoundRecorder := httptest.NewRecorder()
	writeProfileReadError(notFoundRecorder, fmt.Errorf("load profile: %w", domain.ErrProfileNotFound))
	if notFoundRecorder.Code != http.StatusNotFound {
		t.Fatalf("wrapped ErrProfileNotFound status = %d, want %d", notFoundRecorder.Code, http.StatusNotFound)
	}

	fallbackRecorder := httptest.NewRecorder()
	writeProfileReadError(fallbackRecorder, errors.New("profile query failed"))
	if fallbackRecorder.Code != http.StatusInternalServerError {
		t.Fatalf("unrelated error status = %d, want %d", fallbackRecorder.Code, http.StatusInternalServerError)
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

type notificationStore struct {
	app.ProfileStore
	markedUser int
	err        error
}

func (s *notificationStore) Notifications(context.Context, int, int, int) ([]domain.Notification, error) {
	return nil, nil
}
func (s *notificationStore) DeleteNotification(context.Context, int, int) error { return nil }
func (s *notificationStore) MarkAllNotificationsRead(_ context.Context, userID int) error {
	s.markedUser = userID
	return s.err
}

func TestMarkAllNotificationsRead(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}
	for _, tt := range []struct {
		name, id           string
		authenticated      bool
		storeErr           error
		status, markedUser int
	}{
		{name: "success", id: "9", authenticated: true, status: 204, markedUser: 9},
		{name: "unauthenticated", id: "9", status: 401},
		{name: "invalid", id: "invalid", authenticated: true, status: 400},
		{name: "zero", id: "0", authenticated: true, status: 400},
		{name: "other account", id: "10", authenticated: true, status: 403},
		{name: "store failure", id: "9", authenticated: true, storeErr: errors.New("unavailable"), status: 500, markedUser: 9},
	} {
		t.Run(tt.name, func(t *testing.T) {
			store := &notificationStore{err: tt.storeErr}
			service := app.NewProfileService(app.ProfileServiceDependencies{Repository: store})
			handler := NewHandler(Dependencies{Service: service, Verifier: manager})
			router := chi.NewRouter()
			router.Post("/passengers/{id}/notifications/read-all", handler.MarkAllNotificationsRead)
			req := httptest.NewRequest(http.MethodPost, "/passengers/"+tt.id+"/notifications/read-all", nil)
			if tt.authenticated {
				req.Header.Set("Authorization", "Bearer "+token)
			}
			rec := httptest.NewRecorder()
			router.ServeHTTP(rec, req)
			if rec.Code != tt.status {
				t.Fatalf("status = %d, want %d: %s", rec.Code, tt.status, rec.Body.String())
			}
			if store.markedUser != tt.markedUser {
				t.Fatalf("marked user = %d, want %d", store.markedUser, tt.markedUser)
			}
		})
	}
}

func TestRegisteredMarkAllReadRoute(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	store := &notificationStore{}
	routeSecurity := middleware.NewRouteSecurity(middleware.RouteSecurityDependencies{
		Idempotency: middleware.NewIdempotency(middleware.IdempotencyDependencies{Store: middleware.NewMemoryIdempotencyStore()}),
	})
	router := chi.NewRouter()
	NewRouter(Dependencies{Service: app.NewProfileService(app.ProfileServiceDependencies{Repository: store}), Verifier: manager, RouteSecurity: routeSecurity}).RegisterRoutes(router)
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}
	req := httptest.NewRequest(http.MethodPost, "/api/v1/passengers/9/notifications/read-all", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Idempotency-Key", "notification-read-test")
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, req)
	if recorder.Code != http.StatusNoContent {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	if store.markedUser != 9 {
		t.Fatalf("marked user=%d", store.markedUser)
	}
}

type profileUpdateStoreStub struct {
	app.ProfileStore
	profile  domain.Profile
	getCalls int
	getErr   error
	saveErr  error
}

func (s *profileUpdateStoreStub) Get(context.Context, int) (domain.Profile, error) {
	s.getCalls++
	return s.profile, s.getErr
}

func (s *profileUpdateStoreStub) Save(context.Context, domain.Profile) (domain.Profile, error) {
	return domain.Profile{}, s.saveErr
}

func (s *profileUpdateStoreStub) Patch(_ context.Context, _ int, patch domain.ProfilePatch) (domain.Profile, error) {
	if s.saveErr != nil {
		return domain.Profile{}, s.saveErr
	}
	updated, err := domain.ApplyProfilePatch(s.profile, patch)
	if err != nil {
		return domain.Profile{}, err
	}
	s.profile = updated
	return updated, nil
}

func TestProfileUpdateRejectsUnsupportedRole(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	store := &profileUpdateStoreStub{
		profile: domain.Profile{ID: 9, UserID: 9, Role: "unsupported"},
		saveErr: domain.ErrInvalidRole,
	}
	service := app.NewProfileService(app.ProfileServiceDependencies{Repository: store})
	handler := NewHandler(Dependencies{Service: service, Verifier: manager})

	router := chi.NewRouter()
	router.Put("/passengers/{id}", handler.ProfileUpdate)

	req := httptest.NewRequest(http.MethodPut, "/passengers/9", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}
}

func TestProfileUpdateValidatesBlankNameAndVehicleFields(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "driver")
	if err != nil {
		t.Fatal(err)
	}

	store := &profileUpdateStoreStub{
		profile: domain.Profile{ID: 9, UserID: 9, Role: "driver", Name: "Ada", VehicleType: "Sedan", PlateNumber: "ABC123"},
	}
	service := app.NewProfileService(app.ProfileServiceDependencies{Repository: store})
	handler := NewHandler(Dependencies{Service: service, Verifier: manager})
	router := chi.NewRouter()
	router.Patch("/users/me", handler.Update)
	router.Post("/drivers/{id}/online", handler.Online)

	for _, body := range []string{
		`{"name":"   "}`,
		`{"vehicle_type":"   "}`,
		`{"plate_number":"   "}`,
	} {
		req := httptest.NewRequest(http.MethodPatch, "/users/me", strings.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)
		if rec.Code != http.StatusUnprocessableEntity {
			t.Fatalf("body %s: status = %d, want %d: %s", body, rec.Code, http.StatusUnprocessableEntity, rec.Body.String())
		}
	}

	for _, path := range []string{"/drivers/invalid/online", "/drivers/0/online", "/drivers/-1/online"} {
		req := httptest.NewRequest(http.MethodPost, path, strings.NewReader(`{"is_online":true}`))
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("path %s: status = %d, want %d: %s", path, rec.Code, http.StatusBadRequest, rec.Body.String())
		}
	}
}

func TestAvatarUploadReturns413WhenMultipartBodyExceedsMaxBytes(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}
	service := app.NewProfileService(app.ProfileServiceDependencies{Repository: &profileUpdateStoreStub{}})
	handler := NewHandler(Dependencies{Service: service, Verifier: manager})
	router := chi.NewRouter()
	router.Post("/passengers/{id}/avatar", handler.AvatarUpload)

	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	part, err := writer.CreateFormFile("photo", "huge.jpg")
	if err != nil {
		t.Fatal(err)
	}
	// Exceeds MaxAvatarBytes (2 MiB) + 1 MiB envelope limit so ParseMultipartForm hits *http.MaxBytesError.
	if _, err := part.Write(bytes.Repeat([]byte("A"), int(domain.MaxAvatarBytes)+(2<<20))); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}

	req := httptest.NewRequest(http.MethodPost, "/passengers/9/avatar", &body)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusRequestEntityTooLarge {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusRequestEntityTooLarge, rec.Body.String())
	}
}

func TestProfileUpdatePatchesDirectlyWithoutPrecedingGet(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	store := &profileUpdateStoreStub{
		profile: domain.Profile{
			ID:      3,
			UserID:  9,
			Role:    "passenger",
			Name:    "Before",
			Email:   "passenger@example.test",
			Phone:   "+639171234500",
			Address: "Existing Street",
		},
	}
	service := app.NewProfileService(app.ProfileServiceDependencies{Repository: store})
	handler := NewHandler(Dependencies{Service: service, Verifier: manager})
	router := chi.NewRouter()
	router.Patch("/users/me", handler.Update)

	req := httptest.NewRequest(http.MethodPatch, "/users/me", strings.NewReader(`{"name":"After"}`))
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	if store.getCalls != 0 {
		t.Fatalf("expected Update to use Patch without calling Get(), got %d Get calls", store.getCalls)
	}
	if store.profile.Name != "After" || store.profile.Address != "Existing Street" {
		t.Fatalf("updated profile = %#v", store.profile)
	}
}

func TestDriverProfileMalformedIDReturnsDriverError(t *testing.T) {
	manager := security.NewTokenManager("user-handler-test-secret")
	token, err := manager.IssueWithRole("9", "driver")
	if err != nil {
		t.Fatal(err)
	}

	handler := NewHandler(Dependencies{Verifier: manager})
	r := chi.NewRouter()
	r.Get("/drivers/{id}", handler.DriverProfile)

	req := httptest.NewRequest(http.MethodGet, "/drivers/invalid", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "invalid driver id") {
		t.Fatalf("body = %s, want invalid driver id", rec.Body.String())
	}
}
