package users_test

import (
	"context"
	"encoding/json"
	"errors"
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
