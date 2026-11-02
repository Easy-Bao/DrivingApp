package http

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	dispatchapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type stubAvailabilityReader struct {
	summaries []domain.PublicDriverSummary
	online    []domain.OnlineDriver
}

func (s *stubAvailabilityReader) OnlineDrivers(_ context.Context, _ []int) ([]domain.OnlineDriver, error) {
	return s.online, nil
}

func (s *stubAvailabilityReader) PublicDriverSummaries(_ context.Context, _ int) ([]domain.PublicDriverSummary, error) {
	return s.summaries, nil
}

func TestDriverAvailabilityEndpointsRequireAuthentication(t *testing.T) {
	verifier := security.NewTokenManager("test-dispatch-secret")
	reader := &stubAvailabilityReader{
		summaries: []domain.PublicDriverSummary{{ID: 1, Name: "Driver"}},
	}
	router := NewRouter(Dependencies{
		Availability: dispatchapp.NewAvailabilityService(reader),
		Verifier:     verifier,
	})

	mux := chi.NewRouter()
	router.RegisterRoutes(mux)

	endpoints := []struct {
		name string
		path string
	}{
		{name: "public summaries", path: "/api/v1/drivers/public/summaries"},
		{name: "online drivers", path: "/api/v1/drivers/online?ids=1"},
	}

	for _, ep := range endpoints {
		t.Run("unauthenticated_"+ep.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, ep.path, nil)
			response := httptest.NewRecorder()
			mux.ServeHTTP(response, request)

			if response.Code != http.StatusUnauthorized {
				t.Fatalf("%s status = %d, want %d", ep.path, response.Code, http.StatusUnauthorized)
			}
		})

		t.Run("invalid_token_"+ep.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, ep.path, nil)
			request.Header.Set("Authorization", "Bearer invalid-token")
			response := httptest.NewRecorder()
			mux.ServeHTTP(response, request)

			if response.Code != http.StatusUnauthorized {
				t.Fatalf("%s status = %d, want %d", ep.path, response.Code, http.StatusUnauthorized)
			}
		})
	}
}

func TestAvailabilityHandlerDirectCallRejectsUnauthenticated(t *testing.T) {
	handler := NewHandler(Dependencies{})

	// PublicDriverSummaries without identity
	req := httptest.NewRequest(http.MethodGet, "/api/v1/drivers/public/summaries", nil)
	rec := httptest.NewRecorder()
	handler.PublicDriverSummaries(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("PublicDriverSummaries direct call status = %d, want %d", rec.Code, http.StatusUnauthorized)
	}

	// OnlineDrivers without identity
	req = httptest.NewRequest(http.MethodGet, "/api/v1/drivers/online?ids=1", nil)
	rec = httptest.NewRecorder()
	handler.OnlineDrivers(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("OnlineDrivers direct call status = %d, want %d", rec.Code, http.StatusUnauthorized)
	}
}
