package dto

import (
	"encoding/json"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"
)

func TestNewMessageResponsesPreservesLegacyFields(t *testing.T) {
	responses := NewMessageResponses([]domain.Message{{
		RoomID:    "ride-1",
		SenderID:  "driver-7",
		Body:      "I have arrived.",
		CreatedAt: "2026-10-12T09:00:00Z",
	}})
	encoded, err := json.Marshal(responses)
	if err != nil {
		t.Fatalf("marshal message response: %v", err)
	}
	var values []map[string]any
	if err := json.Unmarshal(encoded, &values); err != nil {
		t.Fatalf("unmarshal message response: %v", err)
	}
	if len(values) != 1 {
		t.Fatalf("response count = %d, want 1", len(values))
	}
	for field, want := range map[string]string{
		"text":       "I have arrived.",
		"message":    "I have arrived.",
		"sender_id":  "driver-7",
		"senderId":   "driver-7",
		"created_at": "2026-10-12T09:00:00Z",
		"createdAt":  "2026-10-12T09:00:00Z",
	} {
		if values[0][field] != want {
			t.Fatalf("field %q = %#v, want %q", field, values[0][field], want)
		}
	}
}

func TestNewMessageResponsesKeepsEmptyArrayShape(t *testing.T) {
	encoded, err := json.Marshal(NewMessageResponses(nil))
	if err != nil {
		t.Fatalf("marshal empty message response: %v", err)
	}
	if string(encoded) != "[]" {
		t.Fatalf("empty response = %s, want []", encoded)
	}
}
