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
	ID        string
	ImageKey  string
	Seen      bool
	RoomID    string
	SenderID  string
	Body      string
	CreatedAt string
}
