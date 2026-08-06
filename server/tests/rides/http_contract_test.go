package rides_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

func TestFareRoutesExposeEstimateAndFinalCalculation(t *testing.T) {
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	router := rideshttp.NewRouter(ridesusecase.NewService(nil, config), nil)
	mux := chi.NewRouter()
	router.RegisterRoutes(mux)

	test := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/v1/fares/configs", nil)
	mux.ServeHTTP(test, request)
	if test.Code != http.StatusOK {
		t.Fatalf("fare config status = %d", test.Code)
	}
	var configResponse map[string]any
	if err := json.NewDecoder(test.Body).Decode(&configResponse); err != nil {
		t.Fatalf("decode fare config: %v", err)
	}
	if configResponse["serviceName"] != "Solo Ride" || configResponse["baseFare"] != float64(25) {
		t.Fatalf("unexpected fare config response: %#v", configResponse)
	}
	if _, ok := configResponse["ratingPricingConfig"].(map[string]any); !ok {
		t.Fatalf("rating pricing config is missing: %#v", configResponse)
	}

	test = httptest.NewRecorder()
	request = httptest.NewRequest(http.MethodPost, "/api/v1/fares/calculate-final", http.NoBody)
	mux.ServeHTTP(test, request)
	if test.Code != http.StatusBadRequest {
		t.Fatalf("invalid final fare status = %d", test.Code)
	}
}

func TestDriverAnalyticsRejectsAnotherDriversIdentity(t *testing.T) {
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	verifier := token.NewVerifier("test-secret")
	accessToken, err := verifier.Issue("7")
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}

	mux := chi.NewRouter()
	rideshttp.NewRouter(ridesusecase.NewService(nil, config), verifier).RegisterRoutes(mux)

	for _, path := range []string{
		api.V1Prefix + "/drivers/8/stats",
		api.V1Prefix + "/drivers/8/trips",
	} {
		t.Run(path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, path, nil)
			request.Header.Set("Authorization", "Bearer "+accessToken)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusForbidden {
				t.Fatalf("status = %d, want %d", response.Code, http.StatusForbidden)
			}
		})
	}
}

func TestPublicDriverSummariesExposeRatingsWithoutSensitiveDriverData(t *testing.T) {
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	mux := chi.NewRouter()
	rideshttp.NewRouter(ridesusecase.NewService(analyticsRepository{}, config), nil).RegisterRoutes(mux)

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
	if summaries[0]["name"] != "Ada Driver" || summaries[0]["vehicle_type"] != "Motorcycle" || summaries[0]["rating"] != 4.8 {
		t.Fatalf("unexpected public summary: %#v", summaries[0])
	}
	for _, field := range []string{"user_id", "plate_number", "onboard_passenger_count", "latitude", "longitude"} {
		if _, exists := summaries[0][field]; exists {
			t.Fatalf("public summary leaked %q: %#v", field, summaries[0])
		}
	}

	protectedRequest := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online", nil)
	protectedResponse := httptest.NewRecorder()
	mux.ServeHTTP(protectedResponse, protectedRequest)
	if protectedResponse.Code != http.StatusUnauthorized {
		t.Fatalf("protected online-driver status = %d, want %d", protectedResponse.Code, http.StatusUnauthorized)
	}
}
