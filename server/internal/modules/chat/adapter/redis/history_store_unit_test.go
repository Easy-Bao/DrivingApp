package redis

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
)

func TestMarshalCanonicalMessageOmitsDuplicateLegacyAliases(t *testing.T) {
	payload, err := marshalCanonicalMessage(domain.Message{
		ID:        "msg-1",
		RoomID:    "room-1",
		SenderID:  "7",
		Body:      "hello",
		CreatedAt: "2026-11-27T08:00:00Z",
	})
	if err != nil {
		t.Fatalf("marshalCanonicalMessage() error = %v", err)
	}
	var decoded map[string]any
	if err := json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("json.Unmarshal() error = %v", err)
	}
	for _, legacyKey := range []string{"message", "senderId", "createdAt", "image_key"} {
		if _, exists := decoded[legacyKey]; exists {
			t.Fatalf("unexpected key %q in canonical Redis message: %#v", legacyKey, decoded)
		}
	}
	if decoded["id"] != "msg-1" || decoded["text"] != "hello" || decoded["sender_id"] != "7" || decoded["created_at"] != "2026-11-27T08:00:00Z" {
		t.Fatalf("unexpected canonical fields: %#v", decoded)
	}
}

func TestDecodeStoredMessagesSupportsCanonicalAndLegacyPayloads(t *testing.T) {
	fields := map[string]string{
		"passenger_id": "7",
		"driver_id":    "8",
		"read:8":       "2026-11-27T08:00:00.000000000Z",
	}
	items := []string{
		`{"id":"m1","text":"canonical","sender_id":"7","created_at":"2026-11-27T08:00:00Z"}`,
		`{"message":"legacy","senderId":"8","createdAt":"2026-11-27T08:05:00Z"}`,
	}
	msgs := decodeStoredMessages("room-1", fields, items)
	if len(msgs) != 2 {
		t.Fatalf("decoded count = %d, want 2", len(msgs))
	}
	if !msgs[0].Seen || msgs[0].Body != "canonical" || msgs[0].ID != "m1" {
		t.Fatalf("first message = %#v", msgs[0])
	}
	if msgs[1].Seen || msgs[1].Body != "legacy" || msgs[1].SenderID != "8" || msgs[1].ID == "" {
		t.Fatalf("second message = %#v", msgs[1])
	}
}

func TestHistoryStoreOptionsAndValidation(t *testing.T) {
	store := NewHistoryStore(nil, WithActiveTTL(12*time.Hour), WithResolvedTTL(30*time.Minute), WithMaxMessages(250))
	if store.activeDuration() != 12*time.Hour || store.resolvedDuration() != 30*time.Minute || store.messageLimit() != 250 {
		t.Fatalf("unexpected store config: active=%v resolved=%v limit=%d", store.activeDuration(), store.resolvedDuration(), store.messageLimit())
	}
	if err := store.CreateRoom(context.Background(), "room-1", "7", "8"); err == nil {
		t.Fatal("CreateRoom on nil client succeeded, want error")
	}
}
