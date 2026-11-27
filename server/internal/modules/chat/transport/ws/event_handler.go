package ws

import (
	"context"
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

func (handler *EventHandler) Handle(ctx context.Context, event ClientEvent) error {
	if handler == nil || handler.service == nil {
		return domain.ErrRoomUnavailable
	}
	switch event.Type {
	case "CHAT_MESSAGE", "message":
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
		if !event.HasTyping {
			return fmt.Errorf("%w: missing is_typing in typing event", domain.ErrInvalidMessage)
		}
		return handler.service.PublishTyping(ctx, event.RoomID, event.SenderID, event.IsTyping)
	default:
		return fmt.Errorf("%w: unsupported chat event type %q", domain.ErrInvalidMessage, event.Type)
	}
}
