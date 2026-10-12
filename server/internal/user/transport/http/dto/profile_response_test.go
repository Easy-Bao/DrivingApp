package dto

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

func TestNewProfileResponseKeepsPublicFieldsAndOmitsLastSeen(t *testing.T) {
	t.Parallel()

	lastSeen := time.Date(2026, time.October, 12, 1, 2, 3, 0, time.UTC)
	profile := domain.Profile{
		ID:                7,
		UserID:            42,
		Role:              "driver",
		Name:              "Sample Driver",
		Phone:             "+639171234567",
		Email:             "driver@example.test",
		Address:           "Cebu City",
		Gender:            "unspecified",
		AvatarURL:         "https://example.test/avatar/42",
		PreferredRideType: "motorcycle",
		VehicleType:       "motorcycle",
		PlateNumber:       "ABC1234",
		Rating:            4.8,
		IsOnline:          true,
		OnlineLastSeenAt:  &lastSeen,
	}

	payload, err := json.Marshal(NewProfileResponse(profile))
	if err != nil {
		t.Fatalf("marshal profile response: %v", err)
	}
	const want = `{"id":7,"user_id":42,"role":"driver","name":"Sample Driver","phone":"+639171234567","email":"driver@example.test","address":"Cebu City","gender":"unspecified","avatar_url":"https://example.test/avatar/42","preferred_ride_type":"motorcycle","vehicle_type":"motorcycle","plate_number":"ABC1234","rating":4.8,"is_online":true}`
	if string(payload) != want {
		t.Fatalf("profile response = %s, want %s", payload, want)
	}
}
