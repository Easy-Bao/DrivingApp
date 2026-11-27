package ws

import (
	"encoding/json"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
)

// ClientEvent holds a validated inbound chat WebSocket payload decoded in a single pass.
type ClientEvent struct {
	Type      string
	RoomID    string
	SenderID  string
	Body      string
	Text      string
	IsTyping  bool
	HasTyping bool
}

// ParseClientEvent parses raw client JSON once using exact-key lookups so
// Unicode-folded keys cannot shadow canonical fields.
func ParseClientEvent(message []byte) (ClientEvent, error) {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(message, &fields); err != nil {
		return ClientEvent{}, fmt.Errorf("%w: parse chat event header: %w", domain.ErrInvalidMessage, err)
	}
	if fields == nil {
		return ClientEvent{}, fmt.Errorf("%w: chat event must be a JSON object", domain.ErrInvalidMessage)
	}
	eventType, exists, err := decodeExactStringField(fields, "type")
	if err != nil {
		return ClientEvent{}, fmt.Errorf("%w: parse chat event header: %w", domain.ErrInvalidMessage, err)
	}
	if !exists || eventType == "" {
		return ClientEvent{}, fmt.Errorf("%w: missing chat event type", domain.ErrInvalidMessage)
	}
	event := ClientEvent{Type: eventType}
	roomID, _, err := decodeExactStringField(fields, "room_id")
	if err != nil {
		return ClientEvent{}, fmt.Errorf("%w: parse %s event: %w", domain.ErrInvalidMessage, eventType, err)
	}
	event.RoomID = roomID
	senderID, _, err := decodeExactStringField(fields, "sender_id")
	if err != nil {
		return ClientEvent{}, fmt.Errorf("%w: parse %s event: %w", domain.ErrInvalidMessage, eventType, err)
	}
	event.SenderID = senderID

	switch eventType {
	case "CHAT_MESSAGE", "message":
		body, _, err := decodeExactStringField(fields, "body")
		if err != nil {
			return ClientEvent{}, fmt.Errorf("%w: parse chat message event: %w", domain.ErrInvalidMessage, err)
		}
		text, _, err := decodeExactStringField(fields, "text")
		if err != nil {
			return ClientEvent{}, fmt.Errorf("%w: parse chat message event: %w", domain.ErrInvalidMessage, err)
		}
		event.Body = body
		event.Text = text
		return event, nil
	case "typing":
		isTyping, hasTyping, err := decodeExactTypingFlag(fields)
		if err != nil {
			return ClientEvent{}, fmt.Errorf("%w: parse typing event: %w", domain.ErrInvalidMessage, err)
		}
		if !hasTyping {
			return ClientEvent{}, fmt.Errorf("%w: missing is_typing in typing event", domain.ErrInvalidMessage)
		}
		event.IsTyping = isTyping
		event.HasTyping = true
		return event, nil
	default:
		return ClientEvent{}, fmt.Errorf("%w: unsupported chat event type %q", domain.ErrInvalidMessage, eventType)
	}
}

func decodeExactStringField(fields map[string]json.RawMessage, key string) (string, bool, error) {
	raw, exists := fields[key]
	if !exists || len(raw) == 0 || string(raw) == "null" {
		return "", false, nil
	}
	var value string
	if err := json.Unmarshal(raw, &value); err != nil {
		return "", true, err
	}
	return value, true, nil
}

func decodeExactTypingFlag(fields map[string]json.RawMessage) (bool, bool, error) {
	for _, key := range []string{"is_typing", "isTyping"} {
		raw, exists := fields[key]
		if !exists || len(raw) == 0 || string(raw) == "null" {
			continue
		}
		var value bool
		if err := json.Unmarshal(raw, &value); err != nil {
			return false, false, err
		}
		return value, true, nil
	}
	return false, false, nil
}
