package rides_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
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
