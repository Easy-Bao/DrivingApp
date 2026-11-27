package ws

import (
	"context"
	"errors"
	"fmt"
	"time"

	ports "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
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
	realtimeEvent events.RealtimeEvent,
) error {
	if publisher == nil || publisher.publisher == nil {
		return errors.New("realtime event publisher is unavailable")
	}

	envelope, err := events.New(
		events.NewID(),
		realtimeEvent.Type,
		time.Now(),
		realtimeEvent.Scope,
		NewPayload(realtimeEvent.Payload),
	)
	if err != nil {
		return fmt.Errorf("construct realtime dispatch event: %w", err)
	}
	if err := publisher.publisher.Publish(ctx, envelope); err != nil {
		return fmt.Errorf("publish realtime dispatch event: %w", err)
	}
	return nil
}

var _ ports.EventPublisher = (*EventPublisher)(nil)
