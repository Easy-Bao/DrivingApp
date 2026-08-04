package ws

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
)

type EventHandler struct{ service *usecase.Service }

func NewEventHandler(service *usecase.Service) *EventHandler { return &EventHandler{service: service} }

func (handler *EventHandler) Handle(message []byte) error {
	var event struct {
		Type string `json:"type"`
		domain.Message
	}
	if err := json.Unmarshal(message, &event); err != nil || event.Type != "CHAT_MESSAGE" {
		return nil
	}
	return handler.service.Relay(event.Message)
}
