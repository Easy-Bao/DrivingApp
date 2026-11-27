package app

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

const _completedContactWindow = 24 * time.Hour

// RideAssignment carries the ride participant and lifecycle snapshot required to
// authorize chat rooms without coupling chat to the dispatch module.
type RideAssignment struct {
	RideID      string
	DriverID    string
	PassengerID string
	Status      string
	ContactOpen bool
	CompletedAt *time.Time
}

func (value RideAssignment) AllowsCommunication() bool {
	switch value.Status {
	case "assigned", "accepted", "arrived", "in_transit":
		return true
	case "completed":
		if value.CompletedAt != nil {
			age := time.Since(*value.CompletedAt)
			return age >= 0 && age <= _completedContactWindow
		}
		return value.ContactOpen
	default:
		return false
	}
}

// RideAssignmentLookup authorizes chat rooms against active or recently completed rides.
type RideAssignmentLookup interface {
	ForRide(ctx context.Context, rideID string) (RideAssignment, bool, error)
}

// RideAssignmentLookupFunc adapts a function to RideAssignmentLookup.
type RideAssignmentLookupFunc func(ctx context.Context, rideID string) (RideAssignment, bool, error)

func (fn RideAssignmentLookupFunc) ForRide(ctx context.Context, rideID string) (RideAssignment, bool, error) {
	return fn(ctx, rideID)
}

// ImageStore persists and loads private chat image attachments.
type ImageStore interface {
	Store(ctx context.Context, content []byte) (string, error)
	Read(ctx context.Context, key string, maxBytes int64) ([]byte, error)
	Delete(ctx context.Context, key string) error
}

// RoomStore is the chat application's persistence port for room state and
// retained message history.
type RoomStore interface {
	MarkRead(ctx context.Context, roomID, userID, through string) error
	CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error
	Append(ctx context.Context, message domain.Message) error
	AppendWithParticipants(ctx context.Context, message domain.Message) (passengerID, driverID string, err error)
	Messages(ctx context.Context, roomID string) ([]domain.Message, error)
	FindMessage(ctx context.Context, roomID, messageID string) (domain.Message, bool, error)
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
