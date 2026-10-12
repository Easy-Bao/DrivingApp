package dto

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
	ridedto "github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http/dto"
)

func TestBiddingResponseMappersPreserveWireShapes(t *testing.T) {
	createdAt := time.Date(2026, 10, 12, 14, 0, 0, 0, time.UTC)
	expiresAt := createdAt.Add(2 * time.Minute)
	customFare := int64(1500)
	targetDriverID := 9
	tests := []struct {
		name  string
		value any
		want  string
	}{
		{
			name: "bid session with offer",
			value: NewBidSessionResponse(domain.BidSession{
				ID: 31, PassengerID: 7, RideType: "solo",
				PickupLatitude: 6.7, PickupLongitude: 122.1, PickupName: "Pickup",
				DropoffLatitude: 6.71, DropoffLongitude: 122.11, DropoffName: "Dropoff",
				PassengerNote: "two bags", DistanceKm: 2, DurationMinutes: 10,
				OfferedFareAmount: 1200, CustomFareAmount: &customFare,
				Status: "open", TargetDriverID: &targetDriverID,
				ExpiresAt: expiresAt, CreatedAt: createdAt,
				Offers: []domain.BidOffer{{
					ID: 45, SessionID: 31, DriverID: 9,
					DriverName: "Ada Driver", PlateNumber: "ABC123",
					VehicleType: "Motorcycle", ProposedFareAmount: 1300,
					Status: "pending", CreatedAt: createdAt,
				}},
			}),
			want: `{"id":31,"passenger_id":7,"ride_type":"solo","pickup_latitude":6.7,"pickup_longitude":122.1,"pickup_name":"Pickup","dropoff_latitude":6.71,"dropoff_longitude":122.11,"dropoff_name":"Dropoff","passenger_note":"two bags","distance_km":2,"duration_minutes":10,"offered_fare":1200,"custom_fare":1500,"status":"open","target_driver_id":9,"expires_at":"2026-10-12T14:02:00Z","created_at":"2026-10-12T14:00:00Z","offers":[{"id":45,"session_id":31,"driver_id":9,"driver_name":"Ada Driver","plate_number":"ABC123","vehicle_type":"Motorcycle","proposed_fare":1300,"status":"pending","created_at":"2026-10-12T14:00:00Z"}]}`,
		},
		{
			name: "bid offer omits optional fields",
			value: NewBidOfferResponse(domain.BidOffer{
				ID: 45, SessionID: 31, DriverID: 9,
				ProposedFareAmount: 1300, Status: "pending", CreatedAt: createdAt,
			}),
			want: `{"id":45,"session_id":31,"driver_id":9,"proposed_fare":1300,"status":"pending","created_at":"2026-10-12T14:00:00Z"}`,
		},
		{
			name: "accepted offer response",
			value: AcceptedOfferResponse{
				Session: NewBidSessionResponse(domain.BidSession{ID: 31, PassengerID: 7, Status: "accepted"}),
				Offer:   NewBidOfferResponse(domain.BidOffer{ID: 45, SessionID: 31, DriverID: 9, Status: "accepted"}),
				Ride:    ridedto.RideResponse{ID: 303, PassengerID: 7, Status: "accepted"},
				RideID:  303,
			},
			want: `{"session":{"id":31,"passenger_id":7,"ride_type":"","pickup_latitude":0,"pickup_longitude":0,"pickup_name":"","dropoff_latitude":0,"dropoff_longitude":0,"dropoff_name":"","distance_km":0,"duration_minutes":0,"offered_fare":0,"status":"accepted","expires_at":"0001-01-01T00:00:00Z","created_at":"0001-01-01T00:00:00Z"},"offer":{"id":45,"session_id":31,"driver_id":9,"proposed_fare":0,"status":"accepted","created_at":"0001-01-01T00:00:00Z"},"ride":{"id":303,"passenger_id":7,"status":"accepted","fare_amount":0,"payment_status":"","cash_received_amount":0,"cash_change_amount":0,"cash_outcome":"","commission_amount":0,"driver_payout_amount":0},"ride_id":303}`,
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

func TestBiddingResponseSliceMappersPreserveNil(t *testing.T) {
	if NewBidSessionResponses(nil) != nil {
		t.Fatal("NewBidSessionResponses(nil) returned a non-nil slice")
	}
	if NewBidOfferResponses(nil) != nil {
		t.Fatal("NewBidOfferResponses(nil) returned a non-nil slice")
	}
}
