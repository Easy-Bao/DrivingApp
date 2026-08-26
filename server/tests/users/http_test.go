package users_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
	usershttp "github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type onlineRepository struct {
	profile domain.Profile
	getErr  error
	saved   domain.Profile
}

type avatarRepository struct {
	profile       domain.Profile
	avatar        domain.Avatar
	savedContent  []byte
	savedMimeType string
}

func (repository *avatarRepository) Get(context.Context, int) (domain.Profile, error) {
	return repository.profile, nil
}

func (repository *avatarRepository) Save(_ context.Context, profile domain.Profile) (domain.Profile, error) {
	repository.profile = profile
	return profile, nil
}

func (repository *avatarRepository) SaveAvatar(_ context.Context, _ int, content []byte, contentType string) (domain.Profile, error) {
	repository.savedContent = append([]byte(nil), content...)
	repository.savedMimeType = contentType
	repository.avatar = domain.Avatar{Bytes: append([]byte(nil), content...), ContentType: contentType}
	return repository.profile, nil
}

func (repository *avatarRepository) GetAvatar(context.Context, int) (domain.Avatar, error) {
	return repository.avatar, nil
}

func (repository *onlineRepository) Get(context.Context, int) (domain.Profile, error) {
	if repository.getErr != nil {
		return domain.Profile{}, repository.getErr
	}
	return repository.profile, nil
}

func (repository *onlineRepository) Save(_ context.Context, profile domain.Profile) (domain.Profile, error) {
	repository.saved = profile
	return profile, nil
}

func TestOnlineUpdatesTheExistingDriverProfileForTheAuthenticatedUser(t *testing.T) {
	repository := &onlineRepository{
		profile: domain.Profile{ID: 7, UserID: 42, Role: "driver"},
	}
	tokenManager := security.NewTokenManager("users-http-test-secret")
	token, err := tokenManager.IssueWithRole("42", "driver")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	usershttp.NewRouter(usecase.NewService(repository), tokenManager).RegisterRoutes(router)
	for _, targetID := range []string{"42", "7"} {
		request := httptest.NewRequest(
			http.MethodPost,
			"/api/v1/drivers/"+targetID+"/online",
			strings.NewReader(`{"is_online":true}`),
		)
		request.Header.Set("Authorization", "Bearer "+token)
		response := httptest.NewRecorder()
		router.ServeHTTP(response, request)

		if response.Code != http.StatusOK {
			t.Fatalf("target %s status = %d, body = %s", targetID, response.Code, response.Body.String())
		}
		if repository.saved.ID != 7 || repository.saved.UserID != 42 {
			t.Fatalf("saved profile identity = %#v", repository.saved)
		}
		if !repository.saved.IsOnline {
			t.Fatal("driver profile was not marked online")
		}
	}
}

func TestOnlineDoesNotMaskProfileRepositoryErrorsAsMissingDriverProfiles(t *testing.T) {
	repository := &onlineRepository{getErr: errors.New("database unavailable")}
	tokenManager := security.NewTokenManager("users-http-test-secret")
	token, err := tokenManager.IssueWithRole("42", "driver")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	usershttp.NewRouter(usecase.NewService(repository), tokenManager).RegisterRoutes(router)
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/drivers/42/online",
		strings.NewReader(`{"is_online":true}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusInternalServerError)
	}
}

func TestProfileReturnsAccountContactFieldsForPassengerInfo(t *testing.T) {
	repository := &onlineRepository{
		profile: domain.Profile{
			ID:     7,
			UserID: 42,
			Role:   "passenger",
			Name:   "Xyrel D. Tenefrancia",
			Phone:  "+639501712939",
			Email:  "xdemocrito2@gmail.com",
		},
	}
	tokenManager := security.NewTokenManager("users-http-test-secret")
	token, err := tokenManager.IssueWithRole("42", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	usershttp.NewRouter(usecase.NewService(repository), tokenManager).RegisterRoutes(router)
	request := httptest.NewRequest(http.MethodGet, "/api/v1/passengers/42", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	var payload domain.Profile
	if err := json.Unmarshal(response.Body.Bytes(), &payload); err != nil {
		t.Fatal(err)
	}
	if payload.Name != "Xyrel D. Tenefrancia" ||
		payload.Phone != "+639501712939" ||
		payload.Email != "xdemocrito2@gmail.com" {
		t.Fatalf("profile payload = %#v", payload)
	}
}

func TestProfileUpdateUsesAuthenticatedIdentityAndPersistsAddress(t *testing.T) {
	repository := &onlineRepository{
		profile: domain.Profile{ID: 7, UserID: 42, Role: "passenger", Name: "Before"},
	}
	tokenManager := security.NewTokenManager("users-http-test-secret")
	token, err := tokenManager.IssueWithRole("42", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	usershttp.NewRouter(usecase.NewService(repository), tokenManager).RegisterRoutes(router)
	request := httptest.NewRequest(
		http.MethodPatch,
		"/api/v1/users/me",
		strings.NewReader(`{"name":"After","phone":"+639170000001","email":"after@example.test","address":"Home","gender":"Male"}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	if repository.saved.ID != 7 || repository.saved.UserID != 42 || repository.saved.Role != "passenger" {
		t.Fatalf("profile identity changed during update = %#v", repository.saved)
	}
	if repository.saved.Name != "After" || repository.saved.Address != "Home" || repository.saved.Gender != "Male" {
		t.Fatalf("profile values were not persisted = %#v", repository.saved)
	}

	request = httptest.NewRequest(
		http.MethodPatch,
		"/api/v1/users/me",
		strings.NewReader(`{"id":99}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response = httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusBadRequest {
		t.Fatalf("identity-field status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func TestProfileRejectsUnknownGenderWithoutCallingRepository(t *testing.T) {
	repository := &onlineRepository{
		profile: domain.Profile{ID: 7, UserID: 42, Role: "passenger", Name: "Before"},
	}
	tokenManager := security.NewTokenManager("users-http-test-secret")
	token, err := tokenManager.IssueWithRole("42", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	usershttp.NewRouter(usecase.NewService(repository), tokenManager).RegisterRoutes(router)
	request := httptest.NewRequest(
		http.MethodPatch,
		"/api/v1/users/me",
		strings.NewReader(`{"gender":"unknown"}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusUnprocessableEntity {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusUnprocessableEntity)
	}
	if repository.saved != (domain.Profile{}) {
		t.Fatalf("repository was called for invalid gender = %#v", repository.saved)
	}
	if strings.Contains(response.Body.String(), "unknown") {
		t.Fatalf("invalid gender was reflected to the client: %s", response.Body.String())
	}
}

func TestProfileAvatarUploadAndReadUseAuthenticatedRoutes(t *testing.T) {
	repository := &avatarRepository{
		profile: domain.Profile{ID: 7, UserID: 42, Role: "passenger", Name: "Passenger"},
	}
	tokenManager := security.NewTokenManager("users-http-test-secret")
	token, err := tokenManager.IssueWithRole("42", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	usershttp.NewRouter(usecase.NewService(repository), tokenManager).RegisterRoutes(router)
	avatarBytes := []byte{0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a, 0x00}
	var requestBody bytes.Buffer
	form := multipart.NewWriter(&requestBody)
	file, err := form.CreateFormFile("photo", "profile.png")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := file.Write(avatarBytes); err != nil {
		t.Fatal(err)
	}
	if err := form.Close(); err != nil {
		t.Fatal(err)
	}

	request := httptest.NewRequest(http.MethodPost, "/api/v1/passengers/42/avatar", &requestBody)
	request.Header.Set("Authorization", "Bearer "+token)
	request.Header.Set("Content-Type", form.FormDataContentType())
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("upload status = %d, body = %s", response.Code, response.Body.String())
	}
	if !bytes.Equal(repository.savedContent, avatarBytes) || repository.savedMimeType != "image/png" {
		t.Fatalf("avatar content = %x, mime = %q", repository.savedContent, repository.savedMimeType)
	}

	request = httptest.NewRequest(http.MethodGet, "/api/v1/passengers/42/avatar", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response = httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusOK || response.Header().Get("Content-Type") != "image/png" || !bytes.Equal(response.Body.Bytes(), avatarBytes) {
		t.Fatalf("read response = status %d, type %q, body %x", response.Code, response.Header().Get("Content-Type"), response.Body.Bytes())
	}
}
