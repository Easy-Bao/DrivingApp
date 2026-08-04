package realtime_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	geoh "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http"
	geousecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

type locationRepository struct{ point domain.DriverPoint }

func (repository *locationRepository) Upsert(_ context.Context, point domain.DriverPoint) error {
	repository.point = point
	return nil
}
func (repository *locationRepository) Nearby(context.Context, float64, float64, float64) ([]domain.DriverPoint, error) {
	return nil, nil
}
func (repository *locationRepository) Get(context.Context, string) (domain.DriverPoint, error) {
	return repository.point, nil
}
func (repository *locationRepository) UpsertPassenger(context.Context, string, domain.DriverPoint) error {
	return nil
}
func (repository *locationRepository) GetPassenger(context.Context, string) (domain.DriverPoint, error) {
	return domain.DriverPoint{}, nil
}

func TestTelemetryUsesTheVerifiedSubjectAsDriverID(t *testing.T) {
	repository := &locationRepository{}
	token, err := security.NewTokenManager("secret").Issue("42")
	if err != nil {
		t.Fatal(err)
	}
	router := http.NewServeMux()
	geoh.NewRouter(geousecase.NewService(repository), security.NewTokenManager("secret")).RegisterRoutes(router)
	request := httptest.NewRequest(http.MethodPost, "/telemetry/location", strings.NewReader(`{"driver_id":"attacker","lat":14.1,"lng":120.9}`))
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusAccepted {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	if repository.point.DriverID != "42" {
		t.Fatalf("driver id = %q", repository.point.DriverID)
	}
	var body map[string]any
	if json.Unmarshal(response.Body.Bytes(), &body) != nil {
		t.Fatal("invalid response")
	}
}
