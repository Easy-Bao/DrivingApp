// Package event defines the versioned, transport-neutral messages exchanged
// between the core and realtime services.
package event

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

const CurrentVersion = 1

const maxIdentifierLength = 128

type Type string

const (
	RideOfferCreated         Type = "ride.offer.created"
	RideOfferUpdated         Type = "ride.offer.updated"
	RideMatched              Type = "ride.matched"
	RideStatusChanged        Type = "ride.status.changed"
	DriverLocationUpdated    Type = "driver.location.updated"
	PassengerLocationUpdated Type = "passenger.location.updated"
	ChatMessageCreated       Type = "chat.message.created"
	PresenceUpdated          Type = "presence.updated"
)

// Scope contains the server-authorized identifiers used to route an event.
// A single event can address more than one scope, for example a ride and its
// assigned driver.
type Scope struct {
	RideID      string `json:"ride_id,omitempty"`
	RoomID      string `json:"room_id,omitempty"`
	DriverID    string `json:"driver_id,omitempty"`
	PassengerID string `json:"passenger_id,omitempty"`
}

// Envelope is the common contract persisted only transiently in Pub/Sub and
// forwarded to connected clients. The authoritative state remains in the
// ride and location stores and is recovered through REST snapshots.
type Envelope struct {
	ID         string          `json:"id"`
	Version    int             `json:"version"`
	Type       Type            `json:"type"`
	OccurredAt time.Time       `json:"occurred_at"`
	Scope      Scope           `json:"scope"`
	Payload    json.RawMessage `json:"payload"`
}

func New(id string, eventType Type, occurredAt time.Time, scope Scope, payload map[string]any) (Envelope, error) {
	encodedPayload, err := json.Marshal(payload)
	if err != nil {
		return Envelope{}, fmt.Errorf("marshal realtime event payload: %w", err)
	}

	envelope := Envelope{
		ID:         id,
		Version:    CurrentVersion,
		Type:       eventType,
		OccurredAt: occurredAt.UTC(),
		Scope:      scope,
		Payload:    encodedPayload,
	}
	if err := envelope.Validate(); err != nil {
		return Envelope{}, err
	}
	return envelope, nil
}

func Decode(data []byte) (Envelope, error) {
	var envelope Envelope
	if err := json.Unmarshal(data, &envelope); err != nil {
		return Envelope{}, fmt.Errorf("decode realtime event: %w", err)
	}
	if err := envelope.Validate(); err != nil {
		return Envelope{}, err
	}
	return envelope, nil
}

func (envelope Envelope) Encode() ([]byte, error) {
	if err := envelope.Validate(); err != nil {
		return nil, err
	}
	encoded, err := json.Marshal(envelope)
	if err != nil {
		return nil, fmt.Errorf("encode realtime event: %w", err)
	}
	return encoded, nil
}

func (envelope Envelope) Validate() error {
	if err := validateIdentifier("event id", envelope.ID, true); err != nil {
		return err
	}
	if envelope.Version != CurrentVersion {
		return fmt.Errorf("unsupported realtime event version: %d", envelope.Version)
	}
	if !envelope.Type.valid() {
		return fmt.Errorf("unsupported realtime event type: %q", envelope.Type)
	}
	if envelope.OccurredAt.IsZero() {
		return errors.New("realtime event timestamp is required")
	}
	if err := envelope.Scope.Validate(); err != nil {
		return err
	}
	if err := validatePayload(envelope.Payload); err != nil {
		return err
	}
	return nil
}

func (scope Scope) Validate() error {
	identifiers := []struct {
		name  string
		value string
	}{
		{name: "ride id", value: scope.RideID},
		{name: "room id", value: scope.RoomID},
		{name: "driver id", value: scope.DriverID},
		{name: "passenger id", value: scope.PassengerID},
	}

	hasScope := false
	for _, identifier := range identifiers {
		if identifier.value == "" {
			continue
		}
		hasScope = true
		if err := validateIdentifier(identifier.name, identifier.value, false); err != nil {
			return err
		}
	}
	if !hasScope {
		return errors.New("realtime event scope is required")
	}
	return nil
}

func (eventType Type) valid() bool {
	switch eventType {
	case RideOfferCreated,
		RideOfferUpdated,
		RideMatched,
		RideStatusChanged,
		DriverLocationUpdated,
		PassengerLocationUpdated,
		ChatMessageCreated,
		PresenceUpdated:
		return true
	default:
		return false
	}
}

func validateIdentifier(name, value string, required bool) error {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		if required {
			return fmt.Errorf("%s is required", name)
		}
		return nil
	}
	if value != trimmed {
		return fmt.Errorf("%s must not contain leading or trailing whitespace", name)
	}
	if len(value) > maxIdentifierLength {
		return fmt.Errorf("%s exceeds %d characters", name, maxIdentifierLength)
	}
	return nil
}

func validatePayload(payload json.RawMessage) error {
	trimmed := strings.TrimSpace(string(payload))
	if len(trimmed) == 0 || !json.Valid(payload) {
		return errors.New("realtime event payload must be valid JSON")
	}
	if !strings.HasPrefix(trimmed, "{") || !strings.HasSuffix(trimmed, "}") {
		return errors.New("realtime event payload must be a JSON object")
	}
	var object map[string]json.RawMessage
	if err := json.Unmarshal(payload, &object); err != nil {
		return fmt.Errorf("decode realtime event payload: %w", err)
	}
	return nil
}
