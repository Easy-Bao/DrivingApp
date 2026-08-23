package ws

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
)

type EventHandler struct{ service *usecase.Service }

func NewEventHandler(service *usecase.Service) *EventHandler { return &EventHandler{service: service} }

func (handler *EventHandler) Handle(ctx context.Context, message []byte) error {
	var event struct {
		Type string `json:"type"`
		domain.Message
		Text string `json:"text"`
	}
	if err := json.Unmarshal(message, &event); err != nil || (event.Type != "CHAT_MESSAGE" && event.Type != "message") {
		return nil
	}
	if event.Message.Body == "" {
		event.Message.Body = event.Text
	}
	event.Message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	return handler.service.Relay(ctx, event.Message)
}
