package websocket

import (
	"context"
	"errors"
	"fmt"
	"time"

	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/websocket/dto"
)

type EnvelopePublisher interface {
	Publish(context.Context, events.Envelope) error
}

type EventPublisher struct {
	publisher EnvelopePublisher
}

func NewEventPublisher(publisher EnvelopePublisher) *EventPublisher {
	return &EventPublisher{publisher: publisher}
}

func (publisher *EventPublisher) Publish(
	ctx context.Context,
	realtimeEvent ports.RealtimeEvent,
) error {
	if publisher == nil || publisher.publisher == nil {
		return errors.New("realtime event publisher is unavailable")
	}

	envelope, err := events.New(
		events.NewID(),
		realtimeEvent.Type,
		time.Now(),
		realtimeEvent.Scope,
		dto.NewPayload(realtimeEvent.Payload),
	)
	if err != nil {
		return fmt.Errorf("construct realtime ride event: %w", err)
	}
	if err := publisher.publisher.Publish(ctx, envelope); err != nil {
		return fmt.Errorf("publish realtime ride event: %w", err)
	}
	return nil
}

var _ ports.EventPublisher = (*EventPublisher)(nil)
