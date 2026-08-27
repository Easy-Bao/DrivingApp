package usecase

import (
	"context"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

const (
	maxRoomIDBytes      = 128
	maxParticipantBytes = 128
	maxMessageBytes     = 4096
)

type ChatService struct {
	publisher   domain.Publisher
	history     domain.RoomRepository
	events      EventPublisher
	assignments assignment.Lookup
}

type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}

func NewChatService(publisher domain.Publisher, history domain.RoomRepository) *ChatService {
	return &ChatService{publisher: publisher, history: history}
}

func (service *ChatService) WithEventPublisher(publisher EventPublisher) *ChatService {
	service.events = publisher
	return service
}

func (service *ChatService) WithRideAssignmentLookup(
	lookup assignment.Lookup,
) *ChatService {
	service.assignments = lookup
	return service
}
func (service *ChatService) Relay(ctx context.Context, message domain.Message) error {
	if !validRoomID(message.RoomID) || !validParticipantID(message.SenderID) || len(message.Body) == 0 || len(message.Body) > maxMessageBytes {
		return domain.ErrInvalidMessage
	}
	if service.history == nil {
		return domain.ErrRoomUnavailable
	}
	locked, err := service.history.IsLocked(ctx, message.RoomID)
	if err != nil {
		return err
	}
	if locked {
		return domain.ErrRoomLocked
	}
	member, err := service.history.IsMember(ctx, message.RoomID, message.SenderID)
	if err != nil {
		return err
	}
	if !member {
		return domain.ErrForbidden
	}
	if err := service.history.Append(ctx, message); err != nil {
		return err
	}
	if err := service.publisher.Publish(message); err != nil {
		return err
	}
	service.publishRealtimeMessage(ctx, message)
	return nil
}

func (service *ChatService) publishRealtimeMessage(ctx context.Context, message domain.Message) {
	if service.events == nil || service.history == nil {
		return
	}
	passengerID, driverID, err := service.history.RoomParticipants(ctx, message.RoomID)
	if err != nil || passengerID == "" || driverID == "" {
		return
	}
	occurredAt, err := time.Parse(time.RFC3339Nano, message.CreatedAt)
	if err != nil {
		occurredAt = time.Now().UTC()
	}
	envelope, err := event.New(
		event.NewID(),
		event.ChatMessageCreated,
		occurredAt,
		event.Scope{RoomID: message.RoomID, PassengerID: passengerID, DriverID: driverID},
		map[string]any{
			"room_id":    message.RoomID,
			"sender_id":  message.SenderID,
			"text":       message.Body,
			"created_at": occurredAt.UTC().Format(time.RFC3339Nano),
		},
	)
	if err != nil {
		return
	}
	_ = service.events.Publish(ctx, envelope)
}

func (service *ChatService) OpenRideRoom(ctx context.Context, rideID, actorID string) error {
	if !validRoomID(rideID) || !validParticipantID(actorID) {
		return domain.ErrInvalidRoom
	}
	if service.history == nil {
		return domain.ErrRoomUnavailable
	}
	rideAssignment, err := service.communicationAssignment(ctx, rideID, actorID)
	if err != nil {
		return err
	}
	existingPassengerID, existingDriverID, err := service.history.RoomParticipants(ctx, rideID)
	if err != nil {
		return err
	}
	if existingPassengerID != "" || existingDriverID != "" {
		if existingPassengerID != rideAssignment.PassengerID || existingDriverID != rideAssignment.DriverID {
			return domain.ErrRoomConflict
		}
		locked, err := service.history.IsLocked(ctx, rideID)
		if err != nil {
			return err
		}
		if locked {
			return domain.ErrRoomLocked
		}
		return nil
	}
	return service.history.CreateRoom(ctx, rideID, rideAssignment.PassengerID, rideAssignment.DriverID)
}

func (service *ChatService) communicationAssignment(ctx context.Context, rideID, actorID string) (assignment.Assignment, error) {
	if service.assignments == nil {
		return assignment.Assignment{}, domain.ErrRoomUnavailable
	}
	rideAssignment, found, err := service.assignments.ForRide(ctx, rideID)
	if err != nil {
		return assignment.Assignment{}, domain.ErrRoomUnavailable
	}
	if !found || !rideAssignment.AllowsCommunication() ||
		(actorID != rideAssignment.PassengerID && actorID != rideAssignment.DriverID) {
		return assignment.Assignment{}, domain.ErrForbidden
	}
	return rideAssignment, nil
}

func (service *ChatService) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if !validRoomID(roomID) {
		return nil, domain.ErrInvalidRoom
	}
	if service.history == nil {
		return nil, domain.ErrRoomUnavailable
	}
	return service.history.Messages(ctx, roomID)
}

func (service *ChatService) Resolve(ctx context.Context, roomID string) error {
	if !validRoomID(roomID) {
		return domain.ErrInvalidRoom
	}
	if service.history == nil {
		return domain.ErrRoomUnavailable
	}
	return service.history.Resolve(ctx, roomID)
}

func (service *ChatService) CanAccessRoom(ctx context.Context, roomID, userID string) (bool, error) {
	if !validRoomID(roomID) || !validParticipantID(userID) || service.history == nil {
		return false, nil
	}
	if _, err := service.communicationAssignment(ctx, roomID, userID); err != nil {
		if err == domain.ErrForbidden {
			return false, nil
		}
		return false, err
	}
	member, err := service.history.IsMember(ctx, roomID, userID)
	if err != nil || !member {
		return member, err
	}
	locked, err := service.history.IsLocked(ctx, roomID)
	if err != nil {
		return false, err
	}
	if locked {
		return false, nil
	}
	return true, nil
}

func (service *ChatService) MessagesForUser(ctx context.Context, roomID, userID string) ([]domain.Message, error) {
	if !service.hasAccess(ctx, roomID, userID) {
		return nil, domain.ErrForbidden
	}
	return service.Messages(ctx, roomID)
}

func (service *ChatService) ResolveForUser(ctx context.Context, roomID, userID string) error {
	if !service.hasAccess(ctx, roomID, userID) {
		return domain.ErrForbidden
	}
	return service.Resolve(ctx, roomID)
}

func (service *ChatService) hasAccess(ctx context.Context, roomID, userID string) bool {
	allowed, err := service.CanAccessRoom(ctx, roomID, userID)
	return err == nil && allowed
}

func validRoomID(value string) bool {
	return value != "" && len(value) <= maxRoomIDBytes && !strings.ContainsAny(value, "\r\n")
}

func validParticipantID(value string) bool {
	return value != "" && len(value) <= maxParticipantBytes && !strings.ContainsAny(value, "\r\n")
}
