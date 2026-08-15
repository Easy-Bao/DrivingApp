package driver_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http"
	documentusecase "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

type reviewRepository struct{}

func (reviewRepository) Create(_ context.Context, document domain.Document) (domain.Document, error) {
	return document, nil
}
func (reviewRepository) List(context.Context, int) ([]domain.Document, error) { return nil, nil }
func (reviewRepository) Review(_ context.Context, id int, status domain.Status) (domain.Document, error) {
	return domain.Document{ID: id, Status: status}, nil
}

type documentStorage struct{}

func (documentStorage) Put(context.Context, int, string, []byte) (string, error) {
	return "document", nil
}

func TestReviewRequiresConfiguredAdministrator(t *testing.T) {
	tokenManager := security.NewTokenManager("document-test-secret")
	passengerToken, err := tokenManager.Issue("7")
	if err != nil {
		t.Fatal(err)
	}
	adminToken, err := tokenManager.Issue("42")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	documenthttp.NewRouter(
		documentusecase.NewService(reviewRepository{}, documentStorage{}),
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
			request := httptest.NewRequest(http.MethodPatch, "/api/v1/admin/documents/1/review?status=approved", nil)
			request.Header.Set("Authorization", "Bearer "+test.token)
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d", response.Code, test.status)
			}
		})
	}
}
