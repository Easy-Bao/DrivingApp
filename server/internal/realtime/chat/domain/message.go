package domain

import "context"

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
