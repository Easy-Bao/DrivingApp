package domain

import "context"

// These contracts remain temporarily for callers that still compile against
// the pre-ports package. New code must depend on chat/ports instead.
type HistoryRepository interface {
	CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error
	Append(ctx context.Context, message Message) error
	Messages(ctx context.Context, roomID string) ([]Message, error)
	Resolve(ctx context.Context, roomID string) error
}

type RoomRepository interface {
	HistoryRepository
	RoomParticipantsRepository
	RoomAccessRepository
	RoomLockRepository
}

type RoomParticipantsRepository interface {
	RoomParticipants(ctx context.Context, roomID string) (passengerID, driverID string, err error)
}

type RoomAccessRepository interface {
	IsMember(ctx context.Context, roomID, userID string) (bool, error)
}

type RoomLockRepository interface {
	IsLocked(ctx context.Context, roomID string) (bool, error)
}
