package auth_test

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

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
	authenticate := usecase.NewAuthenticateService(repository, issuer{})
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
