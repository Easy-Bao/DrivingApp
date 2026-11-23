package http

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type routeTestProvider struct{}

func (routeTestProvider) Search(context.Context, string, domain.Coordinates) ([]domain.Place, error) {
	return []domain.Place{{Name: "Robinsons Place"}}, nil
}

func (routeTestProvider) Nearby(context.Context, domain.Coordinates, int) ([]domain.Place, error) {
	return []domain.Place{{Name: "Plaza Luz"}}, nil
}

func (routeTestProvider) ReverseGeocode(context.Context, domain.Coordinates) (*domain.Place, error) {
	return &domain.Place{Name: "Tuburan, Pagadian"}, nil
}

func (routeTestProvider) Route(
	context.Context,
	domain.Coordinates,
	domain.Coordinates,
	domain.RouteOptions,
) (*domain.Route, error) {
	return &domain.Route{DistanceKm: 1.5}, nil
}

func (routeTestProvider) Matrix(context.Context, domain.Coordinates, []domain.Coordinates) (*domain.Matrix, error) {
	return &domain.Matrix{DistancesKm: []float64{1.5}, DurationsMin: []float64{4}}, nil
}

func TestLocationRoutesGuestLookupAndProtectedRouting(t *testing.T) {
	secret := "test-location-routes-secret"
	verifier := security.NewTokenManager(secret)
	service := locationapp.NewService(locationapp.Dependencies{Provider: routeTestProvider{}})
	router := NewRouter(service, verifier)

	mux := chi.NewRouter()
	router.RegisterRoutes(mux)

	validToken, err := verifier.IssueWithRole("42", security.RolePassenger)
	if err != nil {
		t.Fatalf("issue passenger token: %v", err)
	}

	readOnlyEndpoints := []string{
		"/api/v1/location/search?lat=7.8&lng=123.4&q=test",
		"/api/v1/location/nearby?lat=7.8&lng=123.4",
		"/api/v1/location/reverse?lat=7.8&lng=123.4",
	}

	for _, path := range readOnlyEndpoints {
		t.Run("guest_allowed_"+path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, path, nil)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusOK {
				t.Fatalf("GET %s status = %d, want %d", path, response.Code, http.StatusOK)
			}
		})

		t.Run("authenticated_allowed_"+path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, path, nil)
			request.Header.Set("Authorization", "Bearer "+validToken)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusOK {
				t.Fatalf("GET %s status = %d, want %d", path, response.Code, http.StatusOK)
			}
		})

		t.Run("invalid_token_rejected_"+path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, path, nil)
			request.Header.Set("Authorization", "Bearer invalid-token")
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusUnauthorized {
				t.Fatalf("GET %s status = %d, want %d", path, response.Code, http.StatusUnauthorized)
			}
		})
	}

	protectedEndpoints := []string{
		"/api/v1/location/route",
		"/api/v1/location/matrix",
	}

	for _, path := range protectedEndpoints {
		t.Run("unauthenticated_POST_"+path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodPost, path, strings.NewReader(`{}`))
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusUnauthorized {
				t.Fatalf("POST %s status = %d, want %d", path, response.Code, http.StatusUnauthorized)
			}
		})

		t.Run("invalid_token_POST_"+path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodPost, path, strings.NewReader(`{}`))
			request.Header.Set("Authorization", "Bearer invalid-token")
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusUnauthorized {
				t.Fatalf("POST %s status = %d, want %d", path, response.Code, http.StatusUnauthorized)
			}
		})
	}
}

func TestLocationGuestLookupsEnforceRateLimit(t *testing.T) {
	verifier := security.NewTokenManager("test-location-rate-limit-secret")
	service := locationapp.NewService(locationapp.Dependencies{Provider: routeTestProvider{}})
	limiter := middleware.NewRateLimiter(middleware.RateLimiterDependencies{
		Store: middleware.NewMemoryCounterStore(),
		Config: middleware.RateLimitConfig{
			Location: 2,
			Window:   time.Minute,
		},
	})
	routeSecurity := middleware.NewRouteSecurity(middleware.RouteSecurityDependencies{
		RateLimiter: limiter,
	})
	router := NewRouter(service, verifier, routeSecurity)

	mux := chi.NewRouter()
	router.RegisterRoutes(mux)

	for attempt := 1; attempt <= 3; attempt++ {
		request := httptest.NewRequest(http.MethodGet, "/api/v1/location/nearby?lat=7.8&lng=123.4", nil)
		request.RemoteAddr = "203.0.113.10:12345"
		response := httptest.NewRecorder()

		mux.ServeHTTP(response, request)

		want := http.StatusOK
		if attempt == 3 {
			want = http.StatusTooManyRequests
		}
		if response.Code != want {
			t.Fatalf("attempt %d status = %d, want %d", attempt, response.Code, want)
		}
	}
}
