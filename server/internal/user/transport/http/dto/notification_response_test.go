package dto

import (
	"encoding/json"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

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
