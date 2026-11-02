package http

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

func TestLocationRoutesRequireAuthentication(t *testing.T) {
	secret := "test-location-routes-secret"
	verifier := security.NewTokenManager(secret)
	router := NewRouter(nil, verifier)

	mux := chi.NewRouter()
	router.RegisterRoutes(mux)

	endpoints := []struct {
		method string
		path   string
	}{
		{method: http.MethodGet, path: "/api/v1/location/search?lat=7.8&lng=123.4&q=test"},
		{method: http.MethodGet, path: "/api/v1/location/nearby?lat=7.8&lng=123.4"},
		{method: http.MethodGet, path: "/api/v1/location/reverse?lat=7.8&lng=123.4"},
		{method: http.MethodPost, path: "/api/v1/location/route"},
		{method: http.MethodPost, path: "/api/v1/location/matrix"},
	}

	for _, ep := range endpoints {
		t.Run("unauthenticated_"+ep.method+"_"+ep.path, func(t *testing.T) {
			request := httptest.NewRequest(ep.method, ep.path, strings.NewReader(`{}`))
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusUnauthorized {
				t.Fatalf("%s %s status = %d, want %d", ep.method, ep.path, response.Code, http.StatusUnauthorized)
			}
		})

		t.Run("invalid_token_"+ep.method+"_"+ep.path, func(t *testing.T) {
			request := httptest.NewRequest(ep.method, ep.path, strings.NewReader(`{}`))
			request.Header.Set("Authorization", "Bearer invalid-token")
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusUnauthorized {
				t.Fatalf("%s %s status = %d, want %d", ep.method, ep.path, response.Code, http.StatusUnauthorized)
			}
		})
	}
}
