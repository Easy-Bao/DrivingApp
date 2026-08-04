package ws

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"time"
)

type EventHandler struct{ service *usecase.Service }

func NewEventHandler(service *usecase.Service) *EventHandler { return &EventHandler{service: service} }

func (handler *EventHandler) Handle(message []byte) error {
	var event struct {
		Type string `json:"type"`
		domain.Message
		Text      string `json:"text"`
		Sender    string `json:"senderId"`
		CreatedAt string `json:"createdAt"`
	}
	if err := json.Unmarshal(message, &event); err != nil || (event.Type != "CHAT_MESSAGE" && event.Type != "message") {
		return nil
	}
	if event.Message.Body == "" {
		event.Message.Body = event.Text
	}
	if event.Message.SenderID == "" {
		event.Message.SenderID = event.Sender
	}
	if event.Message.CreatedAt == "" {
		event.Message.CreatedAt = event.CreatedAt
	}
	if event.Message.CreatedAt == "" {
		event.Message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	}
	return handler.service.Relay(event.Message)
}
