package http

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
)

func TestNewProfileResponseKeepsPublicFieldsAndOmitsLastSeen(t *testing.T) {
	t.Parallel()

	lastSeen := time.Date(2026, time.October, 12, 1, 2, 3, 0, time.UTC)
	profile := domain.Profile{
		ID:        7,
		UserID:    42,
		Role:      "driver",
		Name:      "Sample Driver",
		Phone:     "+639171234567",
		Email:     "driver@example.test",
		Address:   "Cebu City",
		Gender:    "unspecified",
		AvatarURL: "https://example.test/avatar/42",

		VehicleType:      "motorcycle",
		PlateNumber:      "ABC1234",
		Rating:           4.8,
		IsOnline:         true,
		OnlineLastSeenAt: &lastSeen,
	}

	payload, err := json.Marshal(NewProfileResponse(profile))
	if err != nil {
		t.Fatalf("marshal profile response: %v", err)
	}
	const want = `{"id":7,"user_id":42,"role":"driver","name":"Sample Driver","phone":"+639171234567","email":"driver@example.test","address":"Cebu City","gender":"unspecified","avatar_url":"https://example.test/avatar/42","vehicle_type":"motorcycle","plate_number":"ABC1234","rating":4.8,"is_online":true}`
	if string(payload) != want {
		t.Fatalf("profile response = %s, want %s", payload, want)
	}
}

func TestNewNotificationResponsesPreservesWireFields(t *testing.T) {
	responses := NewNotificationResponses([]domain.Notification{{
		ID:        9,
		UserID:    42,
		Type:      "ride_update",
		Title:     "Ride completed",
		Body:      "Your trip has ended.",
		IsRead:    false,
		CreatedAt: "2026-10-12T09:00:00Z",
	}})
	encoded, err := json.Marshal(responses)
	if err != nil {
		t.Fatalf("marshal notification response: %v", err)
	}
	const want = `[{"id":9,"user_id":42,"type":"ride_update","title":"Ride completed","body":"Your trip has ended.","is_read":false,"created_at":"2026-10-12T09:00:00Z"}]`
	if string(encoded) != want {
		t.Fatalf("notification response = %s, want %s", encoded, want)
	}
}

func TestNewNotificationResponsesKeepsEmptyArrayShape(t *testing.T) {
	encoded, err := json.Marshal(NewNotificationResponses(nil))
	if err != nil {
		t.Fatalf("marshal empty notification response: %v", err)
	}
	if string(encoded) != "[]" {
		t.Fatalf("empty response = %s, want []", encoded)
	}
}
