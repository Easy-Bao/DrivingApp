package ws

import (
	"encoding/json"
	jsonv2 "encoding/json/v2"
	"testing"
	"time"

	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

func TestNewPayloadMapsRideModelsToWireNames(t *testing.T) {
	createdAt := time.Date(2026, 10, 12, 14, 0, 0, 0, time.UTC)
	payload := NewPayload(map[string]any{
		"session": dispatchdomain.BidSession{
			ID: 31, PassengerID: 7, Status: "open", CreatedAt: createdAt,
			Offers: []dispatchdomain.BidOffer{{
				ID: 45, SessionID: 31, DriverID: 9,
				ProposedFareAmount: 1300, Status: "pending", CreatedAt: createdAt,
			}},
		},
		"offer": dispatchdomain.BidOffer{
			ID: 45, SessionID: 31, DriverID: 9,
			ProposedFareAmount: 1300, Status: "pending", CreatedAt: createdAt,
		},
		"ride":   domain.Ride{ID: 303, PassengerID: 7, Status: "accepted"},
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

	session := decodePayloadObject(t, result["session"])
	assertPayloadField(t, session, "id", "31")
	assertPayloadField(t, session, "passenger_id", "7")
	assertPayloadField(t, session, "status", `"open"`)
	if _, exists := session["ID"]; exists {
		t.Fatalf("session contains Go field name: %s", encoded)
	}
	if _, exists := session["passenger_note"]; exists {
		t.Fatalf("session contains an omitted optional field: %s", encoded)
	}

	var offers []json.RawMessage
	if err := json.Unmarshal(session["offers"], &offers); err != nil {
		t.Fatalf("decode nested offers: %v", err)
	}
	if len(offers) != 1 {
		t.Fatalf("nested offer count = %d, want 1", len(offers))
	}
	assertOfferWireFields(t, offers[0])
	assertOfferWireFields(t, result["offer"])

	ride := decodePayloadObject(t, result["ride"])
	assertPayloadField(t, ride, "id", "303")
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

func assertOfferWireFields(t *testing.T, value json.RawMessage) {
	t.Helper()
	offer := decodePayloadObject(t, value)
	assertPayloadField(t, offer, "session_id", "31")
	assertPayloadField(t, offer, "driver_id", "9")
	assertPayloadField(t, offer, "proposed_fare", "1300")
}

func assertPayloadField(t *testing.T, object map[string]json.RawMessage, name, want string) {
	t.Helper()
	if got := string(object[name]); got != want {
		t.Fatalf("payload field %q = %s, want %s", name, got, want)
	}
}
