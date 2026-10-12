package dto

import (
	"encoding/json"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

func TestResponseMappersPreserveWireShapes(t *testing.T) {
	contactAllowedUntil := "2026-10-12T14:30:00Z"
	tests := []struct {
		name  string
		value any
		want  string
	}{
		{
			name: "counterparty",
			value: NewCounterpartyResponse(domain.Counterparty{
				RideID:              17,
				UserID:              9,
				Role:                "driver",
				Name:                "Ada Driver",
				Phone:               "+639000000000",
				Rating:              4.8,
				VehicleType:         "Motorcycle",
				PlateNumber:         "ABC123",
				RideStatus:          "completed",
				ContactAllowed:      true,
				ContactAllowedUntil: &contactAllowedUntil,
			}),
			want: `{"ride_id":17,"user_id":9,"role":"driver","name":"Ada Driver","phone":"+639000000000","rating":4.8,"vehicle_type":"Motorcycle","plate_number":"ABC123","ride_status":"completed","contact_allowed":true,"contact_allowed_until":"2026-10-12T14:30:00Z"}`,
		},
		{
			name: "counterparty omits optional fields",
			value: NewCounterpartyResponse(domain.Counterparty{
				RideID:         17,
				UserID:         9,
				Role:           "passenger",
				Name:           "Ada Passenger",
				RideStatus:     "completed",
				ContactAllowed: false,
			}),
			want: `{"ride_id":17,"user_id":9,"role":"passenger","name":"Ada Passenger","ride_status":"completed","contact_allowed":false}`,
		},
		{
			name: "driver review",
			value: NewReviewResponse(domain.Review{
				ID: 2, RideID: 17, DriverID: 9, PassengerID: 4,
				PassengerName: "Ada Passenger", Rating: 5,
				Comment: "Great trip", CreatedAt: "2026-10-12T14:00:00Z",
			}),
			want: `{"id":2,"ride_id":17,"driver_id":9,"passenger_id":4,"passenger_name":"Ada Passenger","rating":5,"comment":"Great trip","created_at":"2026-10-12T14:00:00Z"}`,
		},
		{
			name:  "driver review omits optional fields",
			value: NewReviewResponses([]domain.Review{{ID: 2, RideID: 17, Rating: 5}}),
			want:  `[{"id":2,"ride_id":17,"driver_id":0,"passenger_id":0,"rating":5,"created_at":""}]`,
		},
		{
			name: "passenger review",
			value: NewPassengerReviewResponse(domain.PassengerReview{
				ID: 3, RideID: 17, DriverID: 9, PassengerID: 4,
				Rating: 4, Comment: "Friendly passenger", CreatedAt: "2026-10-12T14:00:00Z",
			}),
			want: `{"id":3,"ride_id":17,"driver_id":9,"passenger_id":4,"rating":4,"comment":"Friendly passenger","created_at":"2026-10-12T14:00:00Z"}`,
		},
		{
			name: "safety report",
			value: NewSafetyReportResponse(domain.SafetyReport{
				ID: 8, RideID: 17, ReporterID: 4, ReportedUserID: 9,
				ReporterRole: "passenger", Category: domain.SafetyReportUnsafeDriving,
				Severity: domain.SafetyReportHigh, Description: "Unsafe driving",
				Status: domain.SafetyReportSubmitted, CreatedAt: "2026-10-12T14:00:00Z",
			}),
			want: `{"id":8,"ride_id":17,"reporter_id":4,"reported_user_id":9,"reporter_role":"passenger","category":"unsafe_driving","severity":"high","description":"Unsafe driving","status":"submitted","created_at":"2026-10-12T14:00:00Z"}`,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			encoded, err := json.Marshal(test.value)
			if err != nil {
				t.Fatalf("json.Marshal() error = %v", err)
			}
			if string(encoded) != test.want {
				t.Fatalf("response = %s, want %s", encoded, test.want)
			}
		})
	}
}

func TestResponseSliceMappersPreserveNil(t *testing.T) {
	if NewReviewResponses(nil) != nil {
		t.Fatal("NewReviewResponses(nil) returned a non-nil slice")
	}
}
