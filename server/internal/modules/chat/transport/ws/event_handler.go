package ws

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
)

type EventHandler struct{ service *application.Service }

var _ EventSink = (*EventHandler)(nil)

func NewEventHandler(service *application.Service) *EventHandler {
	return &EventHandler{service: service}
}

func (handler *EventHandler) Handle(ctx context.Context, message []byte) error {
	if handler == nil || handler.service == nil {
		return domain.ErrRoomUnavailable
	}
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(message, &fields); err != nil {
		return fmt.Errorf("%w: parse chat event header: %w", domain.ErrInvalidMessage, err)
	}
	if fields == nil {
		return fmt.Errorf("%w: chat event must be a JSON object", domain.ErrInvalidMessage)
	}
	eventType, _, err := decodeExactStringField(fields, "type")
	if err != nil {
		return fmt.Errorf("%w: parse chat event header: %w", domain.ErrInvalidMessage, err)
	}
	switch eventType {
	case "CHAT_MESSAGE", "message":
		roomID, _, err := decodeExactStringField(fields, "room_id")
		if err != nil {
			return fmt.Errorf("%w: parse chat message event: %w", domain.ErrInvalidMessage, err)
		}
		senderID, _, err := decodeExactStringField(fields, "sender_id")
		if err != nil {
			return fmt.Errorf("%w: parse chat message event: %w", domain.ErrInvalidMessage, err)
		}
		body, _, err := decodeExactStringField(fields, "body")
		if err != nil {
			return fmt.Errorf("%w: parse chat message event: %w", domain.ErrInvalidMessage, err)
		}
		text, _, err := decodeExactStringField(fields, "text")
		if err != nil {
			return fmt.Errorf("%w: parse chat message event: %w", domain.ErrInvalidMessage, err)
		}
		if body == "" {
			body = text
		}
		return handler.service.Relay(ctx, domain.Message{
			RoomID:    roomID,
			SenderID:  senderID,
			Body:      body,
			CreatedAt: time.Now().UTC().Format(time.RFC3339Nano),
		})
	case "typing":
		roomID, _, err := decodeExactStringField(fields, "room_id")
		if err != nil {
			return fmt.Errorf("%w: parse typing event: %w", domain.ErrInvalidMessage, err)
		}
		senderID, _, err := decodeExactStringField(fields, "sender_id")
		if err != nil {
			return fmt.Errorf("%w: parse typing event: %w", domain.ErrInvalidMessage, err)
		}
		rawTyping, exists := fields["is_typing"]
		if !exists {
			return fmt.Errorf("%w: missing is_typing in typing event", domain.ErrInvalidMessage)
		}
		var isTyping *bool
		if err := json.Unmarshal(rawTyping, &isTyping); err != nil {
			return fmt.Errorf("%w: parse typing event: %w", domain.ErrInvalidMessage, err)
		}
		if isTyping == nil {
			return fmt.Errorf("%w: missing is_typing in typing event", domain.ErrInvalidMessage)
		}
		return handler.service.PublishTyping(ctx, roomID, senderID, *isTyping)
	default:
		return fmt.Errorf("%w: unsupported chat event type %q", domain.ErrInvalidMessage, eventType)
	}
}

func decodeExactStringField(fields map[string]json.RawMessage, key string) (string, bool, error) {
	raw, exists := fields[key]
	if !exists {
		return "", false, nil
	}
	var value string
	if err := json.Unmarshal(raw, &value); err != nil {
		return "", true, err
	}
	return value, true, nil
}
