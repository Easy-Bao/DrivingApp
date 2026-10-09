package ws

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"
)

type EventHandler struct{ service *application.ChatService }

var _ EventSink = (*EventHandler)(nil)

func NewEventHandler(service *application.ChatService) *EventHandler {
	return &EventHandler{service: service}
}

func (handler *EventHandler) Handle(ctx context.Context, message []byte) error {
	var header struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(message, &header) != nil {
		return nil
	}
	switch header.Type {
	case "CHAT_MESSAGE", "message":
		var event struct {
			domain.Message
			Text string `json:"text"`
		}
		if json.Unmarshal(message, &event) != nil {
			return nil
		}
		if event.Message.Body == "" {
			event.Message.Body = event.Text
		}
		event.Message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
		return handler.service.Relay(ctx, event.Message)
	case "typing":
		var event struct {
			RoomID   string `json:"room_id"`
			SenderID string `json:"sender_id"`
			IsTyping *bool  `json:"is_typing"`
		}
		if json.Unmarshal(message, &event) != nil || event.IsTyping == nil {
			return nil
		}
		return handler.service.PublishTyping(ctx, event.RoomID, event.SenderID, *event.IsTyping)
	default:
		return nil
	}
}
