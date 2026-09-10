package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"
)

// RoomStore is the chat application's persistence port for room state and
// bounded message history.
type RoomStore interface {
	CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error
	Append(ctx context.Context, message domain.Message) error
	Messages(ctx context.Context, roomID string) ([]domain.Message, error)
	Resolve(ctx context.Context, roomID string) error
	RoomParticipants(ctx context.Context, roomID string) (passengerID, driverID string, err error)
	IsMember(ctx context.Context, roomID, userID string) (bool, error)
	IsLocked(ctx context.Context, roomID string) (bool, error)
}
