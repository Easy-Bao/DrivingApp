package auth_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	"github.com/go-chi/chi/v5"
)

func TestRoleSpecificLoginRoutes(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"driver@example.test": {
			ID:           42,
			Email:        "driver@example.test",
			Role:         domain.Driver,
			PasswordHash: usecase.HashPassword("secret"),
		},
		"passenger@example.test": {
			ID:           43,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: usecase.HashPassword("secret"),
		},
	}}
	authenticate := usecase.NewAuthenticateService(repository, issuer{}, newTestRefreshSessionStore())
	mux := chi.NewRouter()
	authhttp.NewRouter(nil, authenticate).RegisterRoutes(mux)

	tests := []struct {
		name           string
		path           string
		email          string
		wantStatusCode int
	}{
		{
			name:           "driver route accepts driver account",
			path:           "/api/v1/auth/driver/login",
			email:          "driver@example.test",
			wantStatusCode: http.StatusOK,
		},
		{
			name:           "driver route rejects passenger account",
			path:           "/api/v1/auth/driver/login",
			email:          "passenger@example.test",
			wantStatusCode: http.StatusUnauthorized,
		},
		{
			name:           "passenger route rejects driver account",
			path:           "/api/v1/auth/passenger/login",
			email:          "driver@example.test",
			wantStatusCode: http.StatusUnauthorized,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(
				http.MethodPost,
				test.path,
				bytes.NewBufferString(`{"email":"`+test.email+`","password":"secret"}`),
			)
			request.Header.Set("Content-Type", "application/json")
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != test.wantStatusCode {
				t.Fatalf("status = %d, want %d", response.Code, test.wantStatusCode)
			}
		})
	}
}

func TestLoginAndRefreshIssueRotatingSessionTokens(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"passenger@example.test": {
			ID:           43,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: usecase.HashPassword("secret"),
		},
	}}
	manager := token.NewIssuer("refresh-http-test-secret")
	authenticate := usecase.NewAuthenticateService(repository, manager, newTestRefreshSessionStore())
	mux := chi.NewRouter()
	authhttp.NewRouter(nil, authenticate).RegisterRoutes(mux)

	loginRequest := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/passenger/login",
		bytes.NewBufferString(`{"email":"passenger@example.test","password":"secret"}`),
	)
	loginResponse := httptest.NewRecorder()
	mux.ServeHTTP(loginResponse, loginRequest)
	if loginResponse.Code != http.StatusOK {
		t.Fatalf("login status = %d, want %d", loginResponse.Code, http.StatusOK)
	}

	var loginBody struct {
		Data struct {
			RefreshToken string `json:"refreshToken"`
		} `json:"data"`
	}
	if err := json.Unmarshal(loginResponse.Body.Bytes(), &loginBody); err != nil {
		t.Fatalf("decode login response: %v", err)
	}
	if loginBody.Data.RefreshToken == "" {
		t.Fatal("expected login to return a refresh token")
	}

	refreshRequest := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/refresh",
		bytes.NewBufferString(`{"refreshToken":"`+loginBody.Data.RefreshToken+`"}`),
	)
	refreshResponse := httptest.NewRecorder()
	mux.ServeHTTP(refreshResponse, refreshRequest)
	if refreshResponse.Code != http.StatusOK {
		t.Fatalf("refresh status = %d, want %d", refreshResponse.Code, http.StatusOK)
	}

	var refreshBody struct {
		Data struct {
			Token        string `json:"token"`
			RefreshToken string `json:"refreshToken"`
		} `json:"data"`
	}
	if err := json.Unmarshal(refreshResponse.Body.Bytes(), &refreshBody); err != nil {
		t.Fatalf("decode refresh response: %v", err)
	}
	if refreshBody.Data.Token == "" || refreshBody.Data.RefreshToken == "" {
		t.Fatal("expected refresh to rotate both session tokens")
	}
}

func TestLoginRejectsFieldsOutsideTheRequestContract(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"passenger@example.test": {
			ID:           43,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: usecase.HashPassword("secret"),
		},
	}}
	mux := chi.NewRouter()
	authhttp.NewRouter(nil, usecase.NewAuthenticateService(repository, issuer{}, newTestRefreshSessionStore())).RegisterRoutes(mux)

	for _, body := range []string{
		`{"email":"passenger@example.test","password":"secret","role":"driver"}`,
		`{"email":"passenger@example.test","password":"secret"}{"email":"other@example.test"}`,
	} {
		request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/passenger/login", bytes.NewBufferString(body))
		response := httptest.NewRecorder()

		mux.ServeHTTP(response, request)

		if response.Code != http.StatusBadRequest {
			t.Fatalf("status = %d, want %d, body = %s", response.Code, http.StatusBadRequest, response.Body.String())
		}
		if response.Header().Get("Content-Type") != "application/problem+json" {
			t.Fatalf("content type = %q", response.Header().Get("Content-Type"))
		}
		var problem struct {
			Code string `json:"code"`
		}
		if err := json.Unmarshal(response.Body.Bytes(), &problem); err != nil || problem.Code != "validation_error" {
			t.Fatalf("problem = %#v, error = %v", problem, err)
		}
	}
}
