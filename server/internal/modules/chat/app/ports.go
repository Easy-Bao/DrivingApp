package app

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

// RoomStore is the chat application's persistence port for room state and
// retained message history.
type RoomStore interface {
	MarkRead(ctx context.Context, roomID, userID, through string) error
	CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error
	Append(ctx context.Context, message domain.Message) error
	Messages(ctx context.Context, roomID string) ([]domain.Message, error)
	Resolve(ctx context.Context, roomID string) error
	RoomParticipants(ctx context.Context, roomID string) (passengerID, driverID string, err error)
	IsMember(ctx context.Context, roomID, userID string) (bool, error)
	IsLocked(ctx context.Context, roomID string) (bool, error)
}

// EventPublisher delivers chat notifications to the process-local event
// transport. REST remains the recovery path for transient delivery gaps.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
