//go:build integration

package auth_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/authentication"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/verification"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

func TestRoleSpecificLoginRoutes(t *testing.T) {
	repository := &repository{users: map[string]domain.User{
		"driver@example.test": {
			ID:           42,
			Email:        "driver@example.test",
			Role:         domain.Driver,
			PasswordHash: testPasswordHash(t, "secret"),
		},
		"passenger@example.test": {
			ID:           43,
			Email:        "passenger@example.test",
			Role:         domain.Passenger,
			PasswordHash: testPasswordHash(t, "secret"),
		},
	}}
	authenticate := authentication.NewAuthenticateService(authentication.Dependencies{
		Repository:   repository,
		Tokens:       issuer{},
		Sessions:     newTestRefreshSessionStore(),
		HashPassword: testHashPassword,
	})
	mux := chi.NewRouter()
	authhttp.NewRouter(
		authhttp.RouterDependencies{Authenticate: authenticate},
		authhttp.WithOTPAttemptStore(middleware.NewMemoryCounterStore()),
	).RegisterRoutes(mux)

	tests := []struct {
		name           string
		path           string
		email          string
		role           string
		wantStatusCode int
		wantSuccessor  string
	}{
		{
			name:           "driver route accepts driver account",
			path:           "/api/v1/auth/driver/login",
			email:          "driver@example.test",
			wantStatusCode: http.StatusOK,
			wantSuccessor:  "/api/v1/auth/login",
		},
		{
			name:           "driver route rejects passenger account",
			path:           "/api/v1/auth/driver/login",
			email:          "passenger@example.test",
			wantStatusCode: http.StatusUnauthorized,
			wantSuccessor:  "/api/v1/auth/login",
		},
		{
			name:           "passenger route rejects driver account",
			path:           "/api/v1/auth/passenger/login",
			email:          "driver@example.test",
			wantStatusCode: http.StatusUnauthorized,
			wantSuccessor:  "/api/v1/auth/login",
		},
		{
			name:           "canonical route accepts matching role",
			path:           "/api/v1/auth/login",
			email:          "driver@example.test",
			role:           "driver",
			wantStatusCode: http.StatusOK,
		},
		{
			name:           "canonical route rejects a different role",
			path:           "/api/v1/auth/login",
			email:          "driver@example.test",
			role:           "passenger",
			wantStatusCode: http.StatusUnauthorized,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			body := `{"email":"` + test.email + `","password":"secret"`
			if test.role != "" {
				body += `,"role":"` + test.role + `"`
			}
			body += `}`
			request := httptest.NewRequest(
				http.MethodPost,
				test.path,
				bytes.NewBufferString(body),
			)
			request.Header.Set("Content-Type", "application/json")
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != test.wantStatusCode {
				t.Fatalf("status = %d, want %d", response.Code, test.wantStatusCode)
			}
			if test.wantSuccessor == "" {
				if response.Header().Get("Deprecation") != "" {
					t.Fatalf("canonical route has Deprecation header %q", response.Header().Get("Deprecation"))
				}
				return
			}
			if response.Header().Get("Deprecation") != "true" {
				t.Fatalf("Deprecation = %q, want true", response.Header().Get("Deprecation"))
			}
			if got := response.Header().Get("Link"); got != "<"+test.wantSuccessor+">; rel=\"successor-version\"" {
				t.Fatalf("Link = %q", got)
			}
		})
	}
}

func TestRoleSpecificRegistrationRoutesRemainCompatibleAliases(t *testing.T) {
	mux := chi.NewRouter()
	authhttp.NewRouter(authhttp.RouterDependencies{}).RegisterRoutes(mux)

	tests := []struct {
		name          string
		legacyPath    string
		canonicalBody string
		legacyBody    string
	}{
		{
			name:          "passenger",
			legacyPath:    "/api/v1/auth/passenger/register",
			canonicalBody: `{"email":"passenger@example.test","phone":"+639171234567","name":"Passenger","password":"secret123","role":"passenger"}`,
			legacyBody:    `{"email":"passenger@example.test","phone":"+639171234567","name":"Passenger","password":"secret123"}`,
		},
		{
			name:          "driver",
			legacyPath:    "/api/v1/auth/driver/register",
			canonicalBody: `{"email":"driver@example.test","phone":"+639171234568","name":"Driver","password":"secret123","vehicle_type":"Sedan","plate_number":"ABC-1234","role":"driver"}`,
			legacyBody:    `{"email":"driver@example.test","phone":"+639171234568","name":"Driver","password":"secret123","vehicle_type":"Sedan","plate_number":"ABC-1234"}`,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			canonicalRequest := httptest.NewRequest(
				http.MethodPost,
				"/api/v1/auth/register",
				bytes.NewBufferString(test.canonicalBody),
			)
			canonicalResponse := httptest.NewRecorder()
			mux.ServeHTTP(canonicalResponse, canonicalRequest)

			legacyRequest := httptest.NewRequest(
				http.MethodPost,
				test.legacyPath,
				bytes.NewBufferString(test.legacyBody),
			)
			legacyResponse := httptest.NewRecorder()
			mux.ServeHTTP(legacyResponse, legacyRequest)

			if legacyResponse.Code != canonicalResponse.Code || legacyResponse.Body.String() != canonicalResponse.Body.String() {
				t.Fatalf(
					"legacy registration = %d %s; canonical = %d %s",
					legacyResponse.Code,
					legacyResponse.Body.String(),
					canonicalResponse.Code,
					canonicalResponse.Body.String(),
				)
			}
			if canonicalResponse.Header().Get("Deprecation") != "" {
				t.Fatalf("canonical registration has Deprecation header %q", canonicalResponse.Header().Get("Deprecation"))
			}
			if legacyResponse.Header().Get("Deprecation") != "true" ||
				legacyResponse.Header().Get("Link") != "</api/v1/auth/register>; rel=\"successor-version\"" {
				t.Fatalf("legacy registration headers = %v", legacyResponse.Header())
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
			PasswordHash: testPasswordHash(t, "secret"),
		},
	}}
	manager := security.NewTokenManager("refresh-http-test-secret")
	authenticate := authentication.NewAuthenticateService(authentication.Dependencies{
		Repository:   repository,
		Tokens:       manager,
		Sessions:     newTestRefreshSessionStore(),
		HashPassword: testHashPassword,
	})
	mux := chi.NewRouter()
	authhttp.NewRouter(authhttp.RouterDependencies{Authenticate: authenticate}).RegisterRoutes(mux)

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
			PasswordHash: testPasswordHash(t, "secret"),
		},
	}}
	mux := chi.NewRouter()
	authhttp.NewRouter(
		authhttp.RouterDependencies{
			Authenticate: authentication.NewAuthenticateService(authentication.Dependencies{
				Repository:   repository,
				Tokens:       issuer{},
				Sessions:     newTestRefreshSessionStore(),
				HashPassword: testHashPassword,
			}),
		},
	).RegisterRoutes(mux)

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

func TestResetPasswordRoutesEnforceOTPAttemptLimit(t *testing.T) {
	tests := []struct {
		name string
		path string
		role domain.Role
	}{
		{name: "passenger", path: "/api/v1/auth/passenger/reset-password", role: domain.Passenger},
		{name: "driver", path: "/api/v1/auth/driver/reset-password", role: domain.Driver},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			email := test.name + "-otp-lockout@example.test"
			repository := &repository{users: map[string]domain.User{
				email: {
					ID:           71,
					Email:        email,
					Role:         test.role,
					PasswordHash: testPasswordHash(t, "old-password"),
				},
			}}
			otpStore := &resetOTPStore{code: "123456"}
			otp := verification.NewOTPService(verification.Dependencies{
				Users:        repository,
				Store:        otpStore,
				Sessions:     newTestRefreshSessionStore(),
				HashPassword: testHashPassword,
			})
			mux := chi.NewRouter()
			authhttp.NewRouter(
				authhttp.RouterDependencies{OTP: otp},
				authhttp.WithOTPAttemptStore(middleware.NewMemoryCounterStore()),
			).RegisterRoutes(mux)

			for attempt := int64(1); attempt <= domain.MaxOTPVerificationAttempts; attempt++ {
				request := httptest.NewRequest(
					http.MethodPost,
					test.path,
					bytes.NewBufferString(`{"email":"`+email+`","code":"000000","newPassword":"new-password"}`),
				)
				request.RemoteAddr = "192.0.2.20:4321"
				request.Header.Set("Content-Type", "application/json")
				response := httptest.NewRecorder()
				mux.ServeHTTP(response, request)

				wantStatus := http.StatusBadRequest
				if attempt == domain.MaxOTPVerificationAttempts {
					wantStatus = http.StatusTooManyRequests
				}
				if response.Code != wantStatus {
					t.Fatalf("attempt %d status = %d, want %d", attempt, response.Code, wantStatus)
				}
				if attempt == domain.MaxOTPVerificationAttempts && response.Header().Get("Retry-After") != "900" {
					t.Fatalf("lockout Retry-After = %q, want 900", response.Header().Get("Retry-After"))
				}
			}
			if otpStore.code != "" {
				t.Fatal("OTP remained usable after the maximum invalid attempts")
			}

			request := httptest.NewRequest(
				http.MethodPost,
				test.path,
				bytes.NewBufferString(`{"email":"`+email+`","code":"000000","newPassword":"new-password"}`),
			)
			request.RemoteAddr = "192.0.2.20:4321"
			request.Header.Set("Content-Type", "application/json")
			response := httptest.NewRecorder()
			mux.ServeHTTP(response, request)

			if response.Code != http.StatusTooManyRequests {
				t.Fatalf("blocked status = %d, want %d", response.Code, http.StatusTooManyRequests)
			}
			if response.Header().Get("Retry-After") != "900" {
				t.Fatalf("Retry-After = %q, want 900", response.Header().Get("Retry-After"))
			}
		})
	}
}

func TestResetPasswordRoutesAcceptValidOTP(t *testing.T) {
	const email = "passenger-reset@example.test"
	repository := &repository{users: map[string]domain.User{
		email: {
			ID:           72,
			Email:        email,
			Role:         domain.Passenger,
			PasswordHash: testPasswordHash(t, "old-password"),
		},
	}}
	otp := verification.NewOTPService(verification.Dependencies{
		Users:        repository,
		Store:        &resetOTPStore{code: "654321"},
		Sessions:     newTestRefreshSessionStore(),
		HashPassword: testHashPassword,
	})
	mux := chi.NewRouter()
	authhttp.NewRouter(
		authhttp.RouterDependencies{OTP: otp},
		authhttp.WithOTPAttemptStore(middleware.NewMemoryCounterStore()),
	).RegisterRoutes(mux)

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/passenger/reset-password",
		bytes.NewBufferString(`{"email":"`+email+`","code":"654321","newPassword":"new-password"}`),
	)
	request.RemoteAddr = "192.0.2.21:4321"
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("reset status = %d, want %d, body = %s", response.Code, http.StatusOK, response.Body.String())
	}
	if !security.VerifyPassword(repository.users[email].PasswordHash, "new-password") {
		t.Fatal("password reset did not store the new password")
	}
}
