package ws

import (
	"encoding/json"
	jsonv2 "encoding/json/v2"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

func TestNewPayloadMapsRideModelsToWireNames(t *testing.T) {
	payload := NewPayload(map[string]any{
		"ride":   domain.Ride{ID: 303, BookingReference: "701698765432100", PassengerID: 7, Status: "accepted"},
		"reason": "driver_unavailable",
	})

	encoded, err := jsonv2.Marshal(payload)
	if err != nil {
		t.Fatalf("jsonv2.Marshal() error = %v", err)
	}
	var result map[string]json.RawMessage
	if err := json.Unmarshal(encoded, &result); err != nil {
		t.Fatalf("decode event payload: %v", err)
	}

	ride := decodePayloadObject(t, result["ride"])
	assertPayloadField(t, ride, "id", "303")
	assertPayloadField(t, ride, "booking_reference", `"701698765432100"`)
	assertPayloadField(t, ride, "passenger_id", "7")
	assertPayloadField(t, ride, "status", `"accepted"`)
	if _, exists := ride["ID"]; exists {
		t.Fatalf("ride contains Go field name: %s", encoded)
	}
	assertPayloadField(t, result, "reason", `"driver_unavailable"`)
}

func decodePayloadObject(t *testing.T, value json.RawMessage) map[string]json.RawMessage {
	t.Helper()
	var object map[string]json.RawMessage
	if err := json.Unmarshal(value, &object); err != nil {
		t.Fatalf("decode payload object: %v", err)
	}
	return object
}

func assertPayloadField(t *testing.T, object map[string]json.RawMessage, name, want string) {
	t.Helper()
	if got := string(object[name]); got != want {
		t.Fatalf("payload field %q = %s, want %s", name, got, want)
	}
}
