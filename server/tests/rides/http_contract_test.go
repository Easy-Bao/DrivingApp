package rides_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	"github.com/go-chi/chi/v5"
)

func TestFareRoutesExposeEstimateAndFinalCalculation(t *testing.T) {
	router := rideshttp.NewRouter(nil, nil)
	mux := chi.NewRouter()
	router.RegisterRoutes(mux)

	test := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/v1/fares/configs", nil)
	mux.ServeHTTP(test, request)
	if test.Code != http.StatusOK {
		t.Fatalf("fare config status = %d", test.Code)
	}

	test = httptest.NewRecorder()
	request = httptest.NewRequest(http.MethodPost, "/api/v1/fares/calculate-final", http.NoBody)
	mux.ServeHTTP(test, request)
	if test.Code != http.StatusBadRequest {
		t.Fatalf("invalid final fare status = %d", test.Code)
	}
}
