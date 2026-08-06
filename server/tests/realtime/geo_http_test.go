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
	"github.com/go-chi/chi/v5"
)

type locationRepository struct{ point domain.DriverPoint }

func (repository *locationRepository) Upsert(_ context.Context, point domain.DriverPoint) error {
	repository.point = point
	return nil
}
func (repository *locationRepository) Nearby(_ context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	if repository.point.DriverID == "" {
		return nil, nil
	}
	if repository.point.Latitude == latitude && repository.point.Longitude == longitude && radiusKm > 0 {
		return []domain.DriverPoint{repository.point}, nil
	}
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
	router := chi.NewRouter()
	geoh.NewRouter(geousecase.NewService(repository), security.NewTokenManager("secret")).RegisterRoutes(router)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/telemetry/location", strings.NewReader(`{"driver_id":"attacker","lat":14.1,"lng":120.9}`))
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

func TestDriverLocationIsVisibleToPassengerAtTheSameCoordinates(t *testing.T) {
	repository := &locationRepository{}
	tokenManager := security.NewTokenManager("secret")
	driverToken, err := tokenManager.Issue("42")
	if err != nil {
		t.Fatal(err)
	}
	passengerToken, err := tokenManager.Issue("99")
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	geoh.NewRouter(geousecase.NewService(repository), tokenManager).RegisterRoutes(router)

	locationRequest := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/telemetry/location",
		strings.NewReader(`{"driverId":"42","lat":7.828,"lng":123.434}`),
	)
	locationRequest.Header.Set("Authorization", "Bearer "+driverToken)
	locationResponse := httptest.NewRecorder()
	router.ServeHTTP(locationResponse, locationRequest)
	if locationResponse.Code != http.StatusAccepted {
		t.Fatalf("location status = %d, body = %s", locationResponse.Code, locationResponse.Body.String())
	}

	nearbyRequest := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/telemetry/location/nearby?latitude=7.828&longitude=123.434&radius_km=5",
		nil,
	)
	nearbyRequest.Header.Set("Authorization", "Bearer "+passengerToken)
	nearbyResponse := httptest.NewRecorder()
	router.ServeHTTP(nearbyResponse, nearbyRequest)
	if nearbyResponse.Code != http.StatusOK {
		t.Fatalf("nearby status = %d, body = %s", nearbyResponse.Code, nearbyResponse.Body.String())
	}

	var body struct {
		Drivers []domain.DriverPoint `json:"drivers"`
	}
	if err := json.Unmarshal(nearbyResponse.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode nearby response: %v", err)
	}
	if len(body.Drivers) != 1 || body.Drivers[0].DriverID != "42" {
		t.Fatalf("nearby drivers = %#v", body.Drivers)
	}
}
