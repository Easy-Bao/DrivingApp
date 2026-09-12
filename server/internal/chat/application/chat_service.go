package application

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"
	chatports "github.com/Easy-Bao/DrivingApp/server/internal/chat/ports"
	assignmentdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/domain"
	assignmentports "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

const (
	maxRoomIDBytes      = 128
	maxParticipantBytes = 128
	maxMessageBytes     = 4096
)

type ChatService struct {
	history     chatports.RoomStore
	events      chatports.EventPublisher
	assignments assignmentports.Lookup
	logger      *slog.Logger
}

type EventPublisher = chatports.EventPublisher

func NewChatService(history chatports.RoomStore) *ChatService {
	return &ChatService{history: history, logger: slog.Default()}
}

func (service *ChatService) WithEventPublisher(publisher EventPublisher) *ChatService {
	service.events = publisher
	return service
}

func (service *ChatService) WithRideAssignmentLookup(
	lookup assignmentports.Lookup,
) *ChatService {
	service.assignments = lookup
	return service
}

func (service *ChatService) WithLogger(logger *slog.Logger) *ChatService {
	if service != nil && logger != nil {
		service.logger = logger
	}
	return service
}

func (service *ChatService) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}

func (service *ChatService) Relay(ctx context.Context, message domain.Message) error {
	invalidRoomID := !validRoomID(message.RoomID)
	invalidSenderID := !validParticipantID(message.SenderID)
	invalidMessageLength := len(message.Body) == 0 || len(message.Body) > maxMessageBytes
	if invalidRoomID || invalidSenderID || invalidMessageLength {
		return domain.ErrInvalidMessage
	}
	if service.history == nil {
		return domain.ErrRoomUnavailable
	}
	locked, err := service.history.IsLocked(ctx, message.RoomID)
	if err != nil {
		return fmt.Errorf("check chat room lock: %w", err)
	}
	if locked {
		return domain.ErrRoomLocked
	}
	member, err := service.history.IsMember(ctx, message.RoomID, message.SenderID)
	if err != nil {
		return fmt.Errorf("check chat room membership: %w", err)
	}
	if !member {
		return domain.ErrForbidden
	}
	if err := service.history.Append(ctx, message); err != nil {
		return fmt.Errorf("append chat message: %w", err)
	}
	service.publishRealtimeMessage(ctx, message)
	return nil
}

func (service *ChatService) publishRealtimeMessage(ctx context.Context, message domain.Message) {
	if service.events == nil || service.history == nil {
		return
	}
	passengerID, driverID, err := service.history.RoomParticipants(ctx, message.RoomID)
	if err != nil {
		service.log().WarnContext(ctx, "load chat room participants for notification failed", "error", err)
		return
	}
	if passengerID == "" || driverID == "" {
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
		service.log().ErrorContext(ctx, "construct chat notification event failed", "error", err)
		return
	}
	if err := service.events.Publish(ctx, envelope); err != nil {
		service.log().WarnContext(ctx, "publish chat notification event failed", "error", err)
	}
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
		return fmt.Errorf("load chat room participants: %w", err)
	}
	if existingPassengerID != "" || existingDriverID != "" {
		if existingPassengerID != rideAssignment.PassengerID || existingDriverID != rideAssignment.DriverID {
			return domain.ErrRoomConflict
		}
		locked, err := service.history.IsLocked(ctx, rideID)
		if err != nil {
			return fmt.Errorf("check chat room lock: %w", err)
		}
		if locked {
			return domain.ErrRoomLocked
		}
		return nil
	}
	if err := service.history.CreateRoom(
		ctx,
		rideID,
		rideAssignment.PassengerID,
		rideAssignment.DriverID,
	); err != nil {
		return fmt.Errorf("create chat room: %w", err)
	}
	return nil
}

func (service *ChatService) communicationAssignment(
	ctx context.Context,
	rideID string,
	actorID string,
) (assignmentdomain.Assignment, error) {
	if service.assignments == nil {
		return assignmentdomain.Assignment{}, domain.ErrRoomUnavailable
	}
	rideAssignment, found, err := service.assignments.ForRide(ctx, rideID)
	if err != nil {
		service.log().WarnContext(ctx, "load ride assignment for chat authorization failed", "error", err)
		return assignmentdomain.Assignment{}, domain.ErrRoomUnavailable
	}
	communicationNotAllowed := !rideAssignment.AllowsCommunication()
	actorIsNotParticipant := actorID != rideAssignment.PassengerID && actorID != rideAssignment.DriverID
	if !found || communicationNotAllowed || actorIsNotParticipant {
		return assignmentdomain.Assignment{}, domain.ErrForbidden
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
	messages, err := service.history.Messages(ctx, roomID)
	if err != nil {
		return nil, fmt.Errorf("load chat messages: %w", err)
	}
	return messages, nil
}

func (service *ChatService) Resolve(ctx context.Context, roomID string) error {
	if !validRoomID(roomID) {
		return domain.ErrInvalidRoom
	}
	if service.history == nil {
		return domain.ErrRoomUnavailable
	}
	if err := service.history.Resolve(ctx, roomID); err != nil {
		return fmt.Errorf("resolve chat room: %w", err)
	}
	return nil
}

func (service *ChatService) CanAccessRoom(ctx context.Context, roomID, userID string) (bool, error) {
	invalidRoomID := !validRoomID(roomID)
	invalidUserID := !validParticipantID(userID)
	if invalidRoomID || invalidUserID {
		return false, nil
	}
	if service.history == nil {
		return false, domain.ErrRoomUnavailable
	}
	if _, err := service.communicationAssignment(ctx, roomID, userID); err != nil {
		if errors.Is(err, domain.ErrForbidden) {
			return false, nil
		}
		return false, err
	}
	member, err := service.history.IsMember(ctx, roomID, userID)
	if err != nil {
		return false, fmt.Errorf("check chat room membership: %w", err)
	}
	if !member {
		return false, nil
	}
	locked, err := service.history.IsLocked(ctx, roomID)
	if err != nil {
		return false, fmt.Errorf("check chat room lock: %w", err)
	}
	if locked {
		return false, nil
	}
	return true, nil
}

func (service *ChatService) MessagesForUser(ctx context.Context, roomID, userID string) ([]domain.Message, error) {
	allowed, err := service.CanAccessRoom(ctx, roomID, userID)
	if err != nil {
		return nil, err
	}
	if !allowed {
		return nil, domain.ErrForbidden
	}
	return service.Messages(ctx, roomID)
}

func (service *ChatService) ResolveForUser(ctx context.Context, roomID, userID string) error {
	allowed, err := service.CanAccessRoom(ctx, roomID, userID)
	if err != nil {
		return err
	}
	if !allowed {
		return domain.ErrForbidden
	}
	return service.Resolve(ctx, roomID)
}

func validRoomID(value string) bool {
	return value != "" && len(value) <= maxRoomIDBytes && !strings.ContainsAny(value, "\r\n")
}

func validParticipantID(value string) bool {
	return value != "" && len(value) <= maxParticipantBytes && !strings.ContainsAny(value, "\r\n")
}
