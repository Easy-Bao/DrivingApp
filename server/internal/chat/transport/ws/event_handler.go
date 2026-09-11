package ws

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"
)

type EventHandler struct{ service *application.ChatService }

func NewEventHandler(service *application.ChatService) *EventHandler {
	return &EventHandler{service: service}
}

func (handler *EventHandler) Handle(ctx context.Context, message []byte) error {
	var event struct {
		Type string `json:"type"`
		domain.Message
		Text string `json:"text"`
	}
	invalidJSON := json.Unmarshal(message, &event) != nil
	invalidEventType := event.Type != "CHAT_MESSAGE" && event.Type != "message"
	if invalidJSON || invalidEventType {
		return nil
	}
	if event.Message.Body == "" {
		event.Message.Body = event.Text
	}
	event.Message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	return handler.service.Relay(ctx, event.Message)
}
