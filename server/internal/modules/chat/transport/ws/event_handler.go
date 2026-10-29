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
	var header struct {
		Type string `json:"type"`
	}
	if err := json.Unmarshal(message, &header); err != nil {
		return fmt.Errorf("%w: parse chat event header: %w", domain.ErrInvalidMessage, err)
	}
	switch header.Type {
	case "CHAT_MESSAGE", "message":
		var event MessageEvent
		if err := json.Unmarshal(message, &event); err != nil {
			return fmt.Errorf("%w: parse chat message event: %w", domain.ErrInvalidMessage, err)
		}
		body := event.Body
		if body == "" {
			body = event.Text
		}
		return handler.service.Relay(ctx, domain.Message{
			RoomID:    event.RoomID,
			SenderID:  event.SenderID,
			Body:      body,
			CreatedAt: time.Now().UTC().Format(time.RFC3339Nano),
		})
	case "typing":
		var event struct {
			RoomID   string `json:"room_id"`
			SenderID string `json:"sender_id"`
			IsTyping *bool  `json:"is_typing"`
		}
		if err := json.Unmarshal(message, &event); err != nil {
			return fmt.Errorf("%w: parse typing event: %w", domain.ErrInvalidMessage, err)
		}
		if event.IsTyping == nil {
			return fmt.Errorf("%w: missing is_typing in typing event", domain.ErrInvalidMessage)
		}
		return handler.service.PublishTyping(ctx, event.RoomID, event.SenderID, *event.IsTyping)
	default:
		return fmt.Errorf("%w: unsupported chat event type %q", domain.ErrInvalidMessage, header.Type)
	}
}
