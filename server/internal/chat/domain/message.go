package domain

import "errors"

var (
	ErrForbidden       = errors.New("chat room access denied")
	ErrInvalidRoom     = errors.New("invalid chat room")
	ErrRoomConflict    = errors.New("chat room participants conflict")
	ErrRoomLocked      = errors.New("chat room is closed")
	ErrRoomUnavailable = errors.New("chat room authorization is unavailable")
	ErrInvalidMessage  = errors.New("invalid chat message")
)

type Message struct {
	RoomID    string `json:"room_id"`
	SenderID  string `json:"sender_id"`
	Body      string `json:"body"`
	CreatedAt string `json:"created_at"`
}
