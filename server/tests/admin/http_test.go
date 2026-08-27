package admin_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/admin/domain"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	adminusecase "github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type httpRepository struct{}

func (httpRepository) Stats(context.Context) (domain.Stats, error) {
	return domain.Stats{Users: 3}, nil
}

func TestStatsRequiresConfiguredAdministrator(t *testing.T) {
	const secret = "admin-test-secret"
	tokenManager := security.NewTokenManager(secret)
	passengerToken, err := tokenManager.Issue("7")
	if err != nil {
		t.Fatal(err)
	}
	adminToken, err := tokenManager.Issue("42")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	adminhttp.NewRouter(
		adminusecase.NewDashboardStatsService(httpRepository{}),
		tokenManager,
		security.NewAdminAuthorizer("42"),
	).RegisterRoutes(router)

	for _, test := range []struct {
		name   string
		token  string
		status int
	}{
		{name: "passenger token", token: passengerToken, status: http.StatusForbidden},
		{name: "administrator token", token: adminToken, status: http.StatusOK},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, "/api/v1/admin/stats", nil)
			request.Header.Set("Authorization", "Bearer "+test.token)
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d", response.Code, test.status)
			}
		})
	}
}
