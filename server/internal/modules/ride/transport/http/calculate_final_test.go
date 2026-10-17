package http

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
)

func TestCalculateFinalUsesServerConfiguredCommission(t *testing.T) {
	pricingConfig := application.PricingConfig{
		BaseFareAmount:        2500,
		PerKilometerAmount:    100,
		PerMinuteAmount:       50,
		PlatformCommissionBPS: 1500,
	}
	service := application.NewRideService(application.RideServiceDependencies{
		PricingConfig: pricingConfig,
	})
	handler := NewHandler(Dependencies{Service: service})

	tests := []struct {
		name       string
		payload    string
		wantCode   int
		wantFare   int64
		wantComm   int64
		wantPayout int64
	}{
		{
			name:       "valid request without client commission",
			payload:    `{"distance_km": 10, "duration_minutes": 20}`,
			wantCode:   http.StatusOK,
			wantFare:   4500,
			wantComm:   675,
			wantPayout: 3825,
		},
		{
			name:     "client supplied commission bps is rejected as unknown field",
			payload:  `{"distance_km": 10, "duration_minutes": 20, "commission_bps": 5000}`,
			wantCode: http.StatusBadRequest,
		},
		{
			name:     "negative distance rejected",
			payload:  `{"distance_km": -1, "duration_minutes": 20}`,
			wantCode: http.StatusBadRequest,
		},
		{
			name:     "negative duration rejected",
			payload:  `{"distance_km": 10, "duration_minutes": -5}`,
			wantCode: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/fares/calculate-final", strings.NewReader(tt.payload))
			req.Header.Set("Content-Type", "application/json")
			rec := httptest.NewRecorder()

			handler.CalculateFinal(rec, req)

			if rec.Code != tt.wantCode {
				t.Fatalf("status = %d, want %d (body: %s)", rec.Code, tt.wantCode, rec.Body.String())
			}
			if tt.wantCode == http.StatusOK {
				var body map[string]any
				if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
					t.Fatalf("unmarshal response: %v", err)
				}
				if fare, ok := body["fare_amount"].(float64); !ok || int64(fare) != tt.wantFare {
					t.Fatalf("fare_amount = %v, want %d", body["fare_amount"], tt.wantFare)
				}
				if comm, ok := body["commission_amount"].(float64); !ok || int64(comm) != tt.wantComm {
					t.Fatalf("commission_amount = %v, want %d", body["commission_amount"], tt.wantComm)
				}
				if payout, ok := body["driver_payout_amount"].(float64); !ok || int64(payout) != tt.wantPayout {
					t.Fatalf("driver_payout_amount = %v, want %d", body["driver_payout_amount"], tt.wantPayout)
				}
			}
		})
	}
}
