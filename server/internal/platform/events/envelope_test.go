package event

import (
	"strings"
	"testing"
	"time"
)

func TestEnvelopeEncodeDecodeRoundTrip(t *testing.T) {
	t.Parallel()

	envelope, err := New(
		"event-1",
		RideOfferCreated,
		time.Date(2026, time.August, 10, 12, 0, 0, 0, time.FixedZone("PHT", 8*60*60)),
		Scope{RideID: "ride-1", DriverID: "driver-1"},
		map[string]any{"offer_id": "offer-1", "fare_centavos": 12000},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	encoded, err := envelope.Encode()
	if err != nil {
		t.Fatalf("Encode() error = %v", err)
	}
	decoded, err := Decode(encoded)
	if err != nil {
		t.Fatalf("Decode() error = %v", err)
	}
	if decoded.ID != envelope.ID || decoded.Type != envelope.Type || decoded.Scope != envelope.Scope {
		t.Fatalf("decoded envelope = %#v, want %#v", decoded, envelope)
	}
	if !decoded.OccurredAt.Equal(envelope.OccurredAt) {
		t.Fatalf("occurred at = %v, want %v", decoded.OccurredAt, envelope.OccurredAt)
	}
}

func TestEnvelopeRejectsInvalidContractValues(t *testing.T) {
	t.Parallel()

	validTimestamp := time.Date(2026, time.August, 10, 10, 0, 0, 0, time.UTC)
	testCases := []struct {
		name     string
		envelope Envelope
		want     string
	}{
		{
			name:     "unsupported version",
			envelope: Envelope{ID: "event-1", Version: 2, Type: RideMatched, OccurredAt: validTimestamp, Scope: Scope{RideID: "ride-1"}, Payload: []byte(`{}`)},
			want:     "version",
		},
		{
			name:     "unsupported event type",
			envelope: Envelope{ID: "event-1", Version: CurrentVersion, Type: "ride.deleted", OccurredAt: validTimestamp, Scope: Scope{RideID: "ride-1"}, Payload: []byte(`{}`)},
			want:     "type",
		},
		{
			name:     "missing scope",
			envelope: Envelope{ID: "event-1", Version: CurrentVersion, Type: RideMatched, OccurredAt: validTimestamp, Payload: []byte(`{}`)},
			want:     "scope",
		},
		{
			name:     "array payload",
			envelope: Envelope{ID: "event-1", Version: CurrentVersion, Type: RideMatched, OccurredAt: validTimestamp, Scope: Scope{RideID: "ride-1"}, Payload: []byte(`[]`)},
			want:     "payload",
		},
	}

	for _, testCase := range testCases {
		testCase := testCase
		t.Run(testCase.name, func(t *testing.T) {
			t.Parallel()
			if err := testCase.envelope.Validate(); err == nil || !strings.Contains(err.Error(), testCase.want) {
				t.Fatalf("Validate() error = %v, want containing %q", err, testCase.want)
			}
		})
	}
}

func TestEnvelopeTopicsAreDerivedFromValidatedScope(t *testing.T) {
	t.Parallel()

	envelope, err := New(
		"event-1",
		RideMatched,
		time.Now().UTC(),
		Scope{RideID: "ride-1", DriverID: "driver-1", PassengerID: "passenger-1"},
		map[string]any{},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	got := envelope.Topics()
	want := []string{"ride:ride-1", "driver:driver-1", "passenger:passenger-1"}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("Topics() = %v, want %v", got, want)
	}
}

func TestDecodeRejectsDuplicateObjectMembers(t *testing.T) {
	t.Parallel()

	_, err := Decode([]byte(`{
        "id":"event-1",
        "version":1,
        "type":"ride.status.changed",
        "occurred_at":"2026-08-10T10:00:00.000Z",
        "scope":{"ride_id":"ride-1"},
        "payload":{"status":"accepted","status":"completed"}
    }`))
	if err == nil {
		t.Fatal("Decode() error = nil, want duplicate-member error")
	}
}
