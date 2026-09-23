package tracking

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
)

type nearbyLocationStore struct {
	nearbyCalls int
}

func (store *nearbyLocationStore) Upsert(context.Context, domain.DriverPoint) error { return nil }

func (store *nearbyLocationStore) Nearby(context.Context, float64, float64, float64) ([]domain.DriverPoint, error) {
	store.nearbyCalls++
	return nil, nil
}

func (store *nearbyLocationStore) Remove(context.Context, string) error { return nil }

func (store *nearbyLocationStore) Get(context.Context, string) (domain.DriverPoint, error) {
	return domain.DriverPoint{}, nil
}

func (store *nearbyLocationStore) UpsertPassenger(context.Context, string, domain.DriverPoint) error {
	return nil
}

func (store *nearbyLocationStore) GetPassenger(context.Context, string) (domain.DriverPoint, error) {
	return domain.DriverPoint{}, nil
}

func TestNearbyDriversClampsThePublicRadiusBoundary(t *testing.T) {
	tests := []struct {
		name       string
		radius     string
		wantStatus int
		wantCalls  int
	}{
		{name: "maximum radius is accepted", radius: "50", wantStatus: http.StatusOK, wantCalls: 1},
		{name: "radius above maximum is rejected", radius: "50.1", wantStatus: http.StatusBadRequest, wantCalls: 0},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			store := &nearbyLocationStore{}
			service := NewLocationTrackingService(store)
			handler := NewHandler(service, nil)
			request := httptest.NewRequest(
				http.MethodGet,
				"/api/v1/telemetry/location/nearby?latitude=6.7&longitude=122.1&radius_km="+test.radius,
				nil,
			)
			response := httptest.NewRecorder()

			handler.NearbyDrivers(response, request)

			if response.Code != test.wantStatus {
				t.Fatalf("status = %d, want %d", response.Code, test.wantStatus)
			}
			if store.nearbyCalls != test.wantCalls {
				t.Fatalf("Nearby() calls = %d, want %d", store.nearbyCalls, test.wantCalls)
			}
		})
	}
}
