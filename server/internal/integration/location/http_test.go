//go:build integration

package location_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/application"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

const locationHTTPTestSecret = "location-http-test-secret"

func TestLocationHTTPRejectsInvalidCoordinatesAsClientErrors(t *testing.T) {
	router := newLocationRouter()

	for _, path := range []string{
		"/api/v1/location/nearby?lat=91&lng=123.4",
		"/api/v1/location/reverse?lat=7.8&lng=181",
	} {
		request := httptest.NewRequest(http.MethodGet, path, nil)
		response := httptest.NewRecorder()

		router.ServeHTTP(response, request)

		if response.Code != http.StatusBadRequest {
			t.Fatalf("%s status = %d, want %d", path, response.Code, http.StatusBadRequest)
		}
	}
}

func TestLocationHTTPRejectsAmbiguousRouteBodies(t *testing.T) {
	router := newLocationRouter()
	payload := `{"origin":{"lat":7.8,"lng":123.4},"destination":{"lat":7.9,"lng":123.5}} {}`
	request := authenticatedRequest(t, http.MethodPost, "/api/v1/location/route", payload)
	response := httptest.NewRecorder()

	router.ServeHTTP(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func TestLocationHTTPRejectsUnsupportedRouteOptions(t *testing.T) {
	router := newLocationRouter()
	payload := `{"origin":{"lat":7.8,"lng":123.4},"destination":{"lat":7.9,"lng":123.5},"profile":"walking"}`
	request := authenticatedRequest(t, http.MethodPost, "/api/v1/location/route", payload)
	response := httptest.NewRecorder()

	router.ServeHTTP(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func TestLocationHTTPExposesSnakeCaseMatrixContract(t *testing.T) {
	router := newLocationRouter()
	payload := `{"origin":{"lat":7.8,"lng":123.4},"destinations":[{"lat":7.9,"lng":123.5}]}`
	request := authenticatedRequest(t, http.MethodPost, "/api/v1/location/matrix", payload)
	response := httptest.NewRecorder()

	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	var body map[string]any
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatalf("decode matrix response: %v", err)
	}
	if _, exists := body["distances_km"]; !exists {
		t.Fatalf("matrix response is missing distances_km: %#v", body)
	}
	if _, exists := body["distancesKm"]; exists {
		t.Fatalf("matrix response leaked a camel-case alias: %#v", body)
	}
}

func TestLocationHTTPRequiresAuthenticationForBillableOperations(t *testing.T) {
	router := newLocationRouter()
	for _, path := range []string{
		"/api/v1/location/route",
		"/api/v1/location/matrix",
	} {
		request := httptest.NewRequest(http.MethodPost, path, strings.NewReader(`{}`))
		response := httptest.NewRecorder()

		router.ServeHTTP(response, request)

		if response.Code != http.StatusUnauthorized {
			t.Errorf("%s status = %d, want %d", path, response.Code, http.StatusUnauthorized)
		}
	}
}

func TestLocationHTTPAllowsAuthenticatedRouteCalculation(t *testing.T) {
	router := newLocationRouter()
	payload := `{"origin":{"lat":7.8,"lng":123.4},"destination":{"lat":7.9,"lng":123.5}}`
	request := authenticatedRequest(t, http.MethodPost, "/api/v1/location/route", payload)
	response := httptest.NewRecorder()

	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
}

func newLocationRouter() *chi.Mux {
	router := chi.NewRouter()
	locationhttp.NewRouter(application.NewLocationService(
		application.LocationServiceDependencies{Provider: providerStub{}},
	), security.NewTokenManager(locationHTTPTestSecret)).RegisterRoutes(router)
	return router
}

func authenticatedRequest(t *testing.T, method, path, payload string) *http.Request {
	t.Helper()
	token, err := security.NewTokenManager(locationHTTPTestSecret).IssueWithRole("42", security.RolePassenger)
	if err != nil {
		t.Fatalf("issue location request token: %v", err)
	}
	request := httptest.NewRequest(method, path, strings.NewReader(payload))
	request.Header.Set("Authorization", "Bearer "+token)
	return request
}
