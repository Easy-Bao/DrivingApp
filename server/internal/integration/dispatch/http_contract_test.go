//go:build integration

package dispatch_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	dispatchhttp "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type availabilityReader struct {
	onlineDrivers []domain.OnlineDriver
	summaries     []domain.PublicDriverSummary
	requestedIDs  []int
	err           error
}

func (reader *availabilityReader) OnlineDrivers(
	_ context.Context,
	driverIDs []int,
) ([]domain.OnlineDriver, error) {
	reader.requestedIDs = append([]int(nil), driverIDs...)
	return reader.onlineDrivers, reader.err
}

func (reader *availabilityReader) PublicDriverSummaries(
	context.Context,
	int,
) ([]domain.PublicDriverSummary, error) {
	return reader.summaries, reader.err
}

func newAvailabilityRouter(
	reader application.DriverAvailabilityReader,
	verifier *security.TokenManager,
) *chi.Mux {
	mux := chi.NewRouter()
	dispatchhttp.NewRouter(dispatchhttp.Dependencies{
		Availability: application.NewAvailabilityService(reader),
		Verifier:     verifier,
	}).RegisterRoutes(mux)
	return mux
}

func TestPublicDriverSummariesPreserveFieldsAndHideSensitiveData(t *testing.T) {
	reader := &availabilityReader{summaries: []domain.PublicDriverSummary{{
		ID: 7, Name: "Ada Driver", VehicleType: "Motorcycle", Rating: 4.8,
	}}}
	mux := newAvailabilityRouter(reader, nil)
	request := httptest.NewRequest(
		http.MethodGet,
		api.V1Prefix+"/drivers/public/summaries?limit=1",
		nil,
	)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	var summaries []map[string]any
	if err := json.NewDecoder(response.Body).Decode(&summaries); err != nil {
		t.Fatalf("decode public driver summaries: %v", err)
	}
	if len(summaries) != 1 {
		t.Fatalf("summaries = %#v, want one item", summaries)
	}
	if summaries[0]["id"] != float64(7) || summaries[0]["name"] != "Ada Driver" ||
		summaries[0]["vehicle_type"] != "Motorcycle" || summaries[0]["rating"] != 4.8 {
		t.Fatalf("unexpected public summary: %#v", summaries[0])
	}
	for _, field := range []string{"user_id", "plate_number", "onboard_passenger_count", "latitude", "longitude"} {
		if _, exists := summaries[0][field]; exists {
			t.Fatalf("public summary leaked %q: %#v", field, summaries[0])
		}
	}

	protectedRequest := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online?ids=7", nil)
	protectedResponse := httptest.NewRecorder()
	mux.ServeHTTP(protectedResponse, protectedRequest)
	if protectedResponse.Code != http.StatusUnauthorized {
		t.Fatalf("protected online-driver status = %d, want %d", protectedResponse.Code, http.StatusUnauthorized)
	}
}

func TestOnlineDriversPreservePassengerAuthorizationAndHideErrors(t *testing.T) {
	reader := &availabilityReader{
		onlineDrivers: []domain.OnlineDriver{{
			ID: 7, UserID: 7, Name: "Ada Driver", VehicleType: "Motorcycle",
			PlateNumber: "XYZ-123", Rating: 4.8, OnboardPassengerCount: 1,
		}},
	}
	verifier := security.NewTokenManager("test-secret")
	passengerToken, err := verifier.IssueWithRole("42", security.RolePassenger)
	if err != nil {
		t.Fatalf("IssueWithRole() returned error: %v", err)
	}
	driverToken, err := verifier.IssueWithRole("43", security.RoleDriver)
	if err != nil {
		t.Fatalf("IssueWithRole() returned error: %v", err)
	}
	mux := newAvailabilityRouter(reader, verifier)

	unauthorizedRequest := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online?ids=7", nil)
	unauthorizedResponse := httptest.NewRecorder()
	mux.ServeHTTP(unauthorizedResponse, unauthorizedRequest)
	if unauthorizedResponse.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized status = %d, want %d", unauthorizedResponse.Code, http.StatusUnauthorized)
	}

	driverRequest := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online?ids=7", nil)
	driverRequest.Header.Set("Authorization", "Bearer "+driverToken)
	driverResponse := httptest.NewRecorder()
	mux.ServeHTTP(driverResponse, driverRequest)
	if driverResponse.Code != http.StatusForbidden {
		t.Fatalf("driver status = %d, want %d", driverResponse.Code, http.StatusForbidden)
	}

	request := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online?ids=7,%208,7", nil)
	request.Header.Set("Authorization", "Bearer "+passengerToken)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	if !reflect.DeepEqual(reader.requestedIDs, []int{7, 8}) {
		t.Fatalf("reader received driver ids %v, want [7 8]", reader.requestedIDs)
	}
	var drivers []map[string]any
	if err := json.NewDecoder(response.Body).Decode(&drivers); err != nil {
		t.Fatalf("decode online drivers: %v", err)
	}
	if len(drivers) != 1 || drivers[0]["id"] != float64(7) || drivers[0]["user_id"] != float64(7) ||
		drivers[0]["plate_number"] != "XYZ-123" || drivers[0]["onboard_passenger_count"] != float64(1) {
		t.Fatalf("unexpected online driver response: %#v", drivers)
	}

	reader.err = errors.New("database password leaked")
	errorRequest := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online?ids=7", nil)
	errorRequest.Header.Set("Authorization", "Bearer "+passengerToken)
	errorResponse := httptest.NewRecorder()
	mux.ServeHTTP(errorResponse, errorRequest)
	if errorResponse.Code != http.StatusServiceUnavailable {
		t.Fatalf("persistence error status = %d, want %d", errorResponse.Code, http.StatusServiceUnavailable)
	}
	if strings.Contains(errorResponse.Body.String(), "database password") {
		t.Fatalf("response leaked persistence details: %s", errorResponse.Body.String())
	}
}
