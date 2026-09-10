package domain

import "context"

// HistoryRepository is the legacy chat persistence port.
//
// Deprecated: use chat/ports.RoomStore instead.
type HistoryRepository interface {
	CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error
	Append(ctx context.Context, message Message) error
	Messages(ctx context.Context, roomID string) ([]Message, error)
	Resolve(ctx context.Context, roomID string) error
}

// RoomRepository is the legacy aggregate chat persistence port.
//
// Deprecated: use chat/ports.RoomStore instead.
type RoomRepository interface {
	HistoryRepository
	RoomParticipantsRepository
	RoomAccessRepository
	RoomLockRepository
}

// RoomParticipantsRepository is the legacy room-participant lookup port.
//
// Deprecated: use chat/ports.RoomStore instead.
type RoomParticipantsRepository interface {
	RoomParticipants(ctx context.Context, roomID string) (passengerID, driverID string, err error)
}

// RoomAccessRepository is the legacy room-membership lookup port.
//
// Deprecated: use chat/ports.RoomStore instead.
type RoomAccessRepository interface {
	IsMember(ctx context.Context, roomID, userID string) (bool, error)
}

// RoomLockRepository is the legacy room-lock lookup port.
//
// Deprecated: use chat/ports.RoomStore instead.
type RoomLockRepository interface {
	IsLocked(ctx context.Context, roomID string) (bool, error)
}
