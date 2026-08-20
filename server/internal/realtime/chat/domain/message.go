package domain

import (
	"context"
	"errors"
)

var (
	ErrForbidden       = errors.New("chat room access denied")
	ErrInvalidRoom     = errors.New("invalid chat room")
	ErrRoomConflict    = errors.New("chat room participants conflict")
	ErrRoomUnavailable = errors.New("chat room authorization is unavailable")
	ErrInvalidMessage  = errors.New("invalid chat message")
)

type Message struct {
	RoomID    string `json:"room_id"`
	SenderID  string `json:"sender_id"`
	Body      string `json:"body"`
	CreatedAt string `json:"created_at"`
}
type Publisher interface{ Publish(message Message) error }

type HistoryRepository interface {
	CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error
	Append(ctx context.Context, message Message) error
	Messages(ctx context.Context, roomID string) ([]Message, error)
	Resolve(ctx context.Context, roomID string) error
}

type RoomParticipantsRepository interface {
	RoomParticipants(ctx context.Context, roomID string) (passengerID, driverID string, err error)
}

type RoomAccessRepository interface {
	IsMember(ctx context.Context, roomID, userID string) (bool, error)
}
