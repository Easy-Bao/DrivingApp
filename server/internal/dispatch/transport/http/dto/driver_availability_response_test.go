package dto

import (
	"encoding/json"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
)

func TestDriverAvailabilityResponsesPreserveWireShapes(t *testing.T) {
	onlineDrivers, err := json.Marshal(NewOnlineDriverResponses([]domain.OnlineDriver{{
		ID: 9, UserID: 4, Name: "Ada Driver", VehicleType: "Motorcycle",
		PlateNumber: "ABC123", Rating: 4.8, OnboardPassengerCount: 1,
	}}))
	if err != nil {
		t.Fatalf("marshal online drivers: %v", err)
	}
	if got, want := string(onlineDrivers), `[{"id":9,"user_id":4,"name":"Ada Driver","vehicle_type":"Motorcycle","plate_number":"ABC123","rating":4.8,"onboard_passenger_count":1}]`; got != want {
		t.Fatalf("online drivers = %s, want %s", got, want)
	}

	summaries, err := json.Marshal(NewPublicDriverSummaryResponses([]domain.PublicDriverSummary{{
		ID: 9, Name: "Ada Driver", VehicleType: "Motorcycle", Rating: 4.8,
	}}))
	if err != nil {
		t.Fatalf("marshal public driver summaries: %v", err)
	}
	if got, want := string(summaries), `[{"id":9,"name":"Ada Driver","vehicle_type":"Motorcycle","rating":4.8}]`; got != want {
		t.Fatalf("public driver summaries = %s, want %s", got, want)
	}
}

func TestDriverAvailabilityResponseMappersPreserveNil(t *testing.T) {
	if NewOnlineDriverResponses(nil) != nil {
		t.Fatal("NewOnlineDriverResponses(nil) returned a non-nil slice")
	}
	if NewPublicDriverSummaryResponses(nil) != nil {
		t.Fatal("NewPublicDriverSummaryResponses(nil) returned a non-nil slice")
	}
}
