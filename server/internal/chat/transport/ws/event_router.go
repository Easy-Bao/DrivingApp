package ws

import (
	"context"
	"encoding/json"
	"fmt"
)

// EventRouter keeps event ownership explicit: location tracking and chat
// receive only messages belonging to their bounded context.
type EventRouter struct{ handlers map[string]EventSink }

func NewEventRouter() *EventRouter { return &EventRouter{handlers: map[string]EventSink{}} }

func (router *EventRouter) Register(eventType string, handler EventSink) {
	router.handlers[eventType] = handler
}

func (router *EventRouter) Handle(ctx context.Context, message []byte) error {
	var event struct {
		Type string `json:"type"`
	}
	if err := json.Unmarshal(message, &event); err != nil {
		return fmt.Errorf("decode chat websocket event: %w", err)
	}
	if handler := router.handlers[event.Type]; handler != nil {
		if err := handler.Handle(ctx, message); err != nil {
			return fmt.Errorf("handle chat websocket event: %w", err)
		}
	}
	return nil
}
