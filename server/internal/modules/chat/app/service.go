package app

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"log/slog"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	assignment "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
)

const (
	_maxRoomIDBytes          = 128
	_maxParticipantBytes     = 128
	_maxMessageBytes         = 4096
	_chatEventPublishTimeout = 2 * time.Second
)

type Service struct {
	images      storage.ObjectStore
	history     RoomStore
	events      EventPublisher
	assignments assignment.Lookup
	logger      *slog.Logger
}

type Dependencies struct {
	History RoomStore
	Images  storage.ObjectStore
}

func NewService(dependencies Dependencies) *Service {
	return &Service{history: dependencies.History, images: dependencies.Images, logger: slog.Default()}
}

func (service *Service) WithEventPublisher(publisher EventPublisher) *Service {
	if service != nil {
		service.events = publisher
	}
	return service
}

func (service *Service) WithRideAssignmentLookup(
	lookup assignment.Lookup,
) *Service {
	if service != nil {
		service.assignments = lookup
	}
	return service
}

func (service *Service) WithLogger(logger *slog.Logger) *Service {
	if service != nil && logger != nil {
		service.logger = logger
	}
	return service
}

func (service *Service) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}

func (service *Service) Relay(ctx context.Context, message domain.Message) error {
	invalidRoomID := !validRoomID(message.RoomID)
	invalidSenderID := !validParticipantID(message.SenderID)
	invalidMessageLength := (strings.TrimSpace(message.Body) == "" && message.ImageKey == "") || len(message.Body) > _maxMessageBytes
	if invalidRoomID || invalidSenderID || invalidMessageLength {
		return domain.ErrInvalidMessage
	}
	if service == nil || service.history == nil {
		return domain.ErrRoomUnavailable
	}
	if _, err := service.communicationAssignment(ctx, message.RoomID, message.SenderID); err != nil {
		return err
	}
	if message.ID == "" {
		message.ID = event.NewID()
	}
	if message.CreatedAt == "" {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	} else if parsed, err := time.Parse(time.RFC3339Nano, message.CreatedAt); err != nil {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	} else {
		message.CreatedAt = parsed.UTC().Format(time.RFC3339Nano)
	}
	passengerID, driverID, err := service.history.AppendWithParticipants(ctx, message)
	if err != nil {
		return fmt.Errorf("append chat message: %w", err)
	}
	service.publishRealtimeMessageWithParticipants(ctx, message, passengerID, driverID)
	return nil
}

func (service *Service) PublishTyping(ctx context.Context, roomID, senderID string, isTyping bool) error {
	if !validRoomID(roomID) || !validParticipantID(senderID) {
		return domain.ErrInvalidMessage
	}
	allowed, err := service.CanAccessRoom(ctx, roomID, senderID)
	if err != nil {
		return fmt.Errorf("authorize chat typing event: %w", err)
	}
	if !allowed {
		return domain.ErrForbidden
	}
	if service.events == nil {
		return nil
	}

	envelope, err := event.New(
		event.NewID(),
		event.ChatTypingChanged,
		time.Now().UTC(),
		event.Scope{RoomID: roomID},
		map[string]any{"sender_id": senderID, "is_typing": isTyping},
	)
	if err != nil {
		return fmt.Errorf("construct chat typing event: %w", err)
	}
	if err := service.events.Publish(ctx, envelope); err != nil {
		service.log().WarnContext(ctx, "publish chat typing event failed", "error", err)
	}
	return nil
}

func (service *Service) publishRealtimeMessageWithParticipants(
	ctx context.Context,
	message domain.Message,
	passengerID string,
	driverID string,
) {
	if service.events == nil || passengerID == "" || driverID == "" {
		return
	}
	occurredAt, err := time.Parse(time.RFC3339Nano, message.CreatedAt)
	if err != nil {
		occurredAt = time.Now().UTC()
	}
	envelope, err := event.New(
		message.ID,
		event.ChatMessageCreated,
		occurredAt,
		event.Scope{RoomID: message.RoomID, PassengerID: passengerID, DriverID: driverID},
		map[string]any{
			"id":         message.ID,
			"image_key":  message.ImageKey,
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
	publishCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), _chatEventPublishTimeout)
	defer cancel()
	if err := service.events.Publish(publishCtx, envelope); err != nil {
		service.log().WarnContext(ctx, "publish chat notification event failed", "error", err)
	}
}

func (service *Service) OpenRideRoom(ctx context.Context, rideID, actorID string) error {
	if !validRoomID(rideID) || !validParticipantID(actorID) {
		return domain.ErrInvalidRoom
	}
	if service == nil || service.history == nil {
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

func (service *Service) participantAssignment(
	ctx context.Context,
	rideID string,
	actorID string,
) (assignment.Assignment, error) {
	if service == nil || service.assignments == nil {
		return assignment.Assignment{}, domain.ErrRoomUnavailable
	}
	rideAssignment, found, err := service.assignments.ForRide(ctx, rideID)
	if err != nil {
		service.log().WarnContext(ctx, "load ride assignment for chat authorization failed", "error", err)
		return assignment.Assignment{}, domain.ErrRoomUnavailable
	}
	if !found {
		return assignment.Assignment{}, domain.ErrForbidden
	}
	actorIsNotParticipant := actorID != rideAssignment.PassengerID && actorID != rideAssignment.DriverID
	if actorIsNotParticipant {
		return assignment.Assignment{}, domain.ErrForbidden
	}
	return rideAssignment, nil
}

func (service *Service) communicationAssignment(ctx context.Context, roomID, userID string) (assignment.Assignment, error) {
	value, err := service.participantAssignment(ctx, roomID, userID)
	if err != nil {
		return value, err
	}
	if !value.AllowsCommunication() {
		return value, domain.ErrRoomLocked
	}
	return value, nil
}

// Read access survives closure and is checked against the authoritative ride.
func (service *Service) CanReadRoom(ctx context.Context, roomID, userID string) (bool, error) {
	if !validRoomID(roomID) || !validParticipantID(userID) {
		return false, nil
	}
	if service == nil || service.history == nil {
		return false, domain.ErrRoomUnavailable
	}
	_, err := service.participantAssignment(ctx, roomID, userID)
	if errors.Is(err, domain.ErrForbidden) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	passengerID, driverID, err := service.history.RoomParticipants(ctx, roomID)
	if err != nil {
		return false, fmt.Errorf("load chat participants: %w", err)
	}
	if passengerID == "" && driverID == "" {
		return true, nil
	}
	return userID == passengerID || userID == driverID, nil
}

func (service *Service) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if !validRoomID(roomID) {
		return nil, domain.ErrInvalidRoom
	}
	if service == nil || service.history == nil {
		return nil, domain.ErrRoomUnavailable
	}
	messages, err := service.history.Messages(ctx, roomID)
	if err != nil {
		return nil, fmt.Errorf("load chat messages: %w", err)
	}
	return slices.Clone(messages), nil
}

func (service *Service) Resolve(ctx context.Context, roomID string) error {
	if !validRoomID(roomID) {
		return domain.ErrInvalidRoom
	}
	if service == nil || service.history == nil {
		return domain.ErrRoomUnavailable
	}
	if err := service.history.Resolve(ctx, roomID); err != nil {
		return fmt.Errorf("resolve chat room: %w", err)
	}
	return nil
}

func (service *Service) CanAccessRoom(ctx context.Context, roomID, userID string) (bool, error) {
	invalidRoomID := !validRoomID(roomID)
	invalidUserID := !validParticipantID(userID)
	if invalidRoomID || invalidUserID {
		return false, nil
	}
	if service == nil || service.history == nil {
		return false, domain.ErrRoomUnavailable
	}
	if _, err := service.communicationAssignment(ctx, roomID, userID); err != nil {
		if errors.Is(err, domain.ErrForbidden) || errors.Is(err, domain.ErrRoomLocked) {
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

func (service *Service) MessagesForUser(ctx context.Context, roomID, userID string) ([]domain.Message, error) {
	allowed, err := service.CanReadRoom(ctx, roomID, userID)
	if err != nil {
		return nil, err
	}
	if !allowed {
		return nil, domain.ErrForbidden
	}
	return service.Messages(ctx, roomID)
}

func (service *Service) ResolveForUser(ctx context.Context, roomID, userID string) error {
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
	return validChatIdentifier(value, _maxRoomIDBytes)
}

func validParticipantID(value string) bool {
	return validChatIdentifier(value, _maxParticipantBytes)
}

func validChatIdentifier(value string, maxBytes int) bool {
	return value != "" && len(value) <= maxBytes && !strings.ContainsAny(value, "\r\n")
}

const MaxImageBytes = 5 << 20

func (service *Service) SendImage(ctx context.Context, roomID, userID string, content []byte) (domain.Message, error) {
	if !validRoomID(roomID) || !validParticipantID(userID) {
		return domain.Message{}, domain.ErrInvalidMessage
	}
	if service == nil || service.history == nil || service.images == nil {
		return domain.Message{}, domain.ErrRoomUnavailable
	}
	if _, err := service.communicationAssignment(ctx, roomID, userID); err != nil {
		return domain.Message{}, err
	}
	if len(content) == 0 || len(content) > MaxImageBytes {
		return domain.Message{}, domain.ErrInvalidMessage
	}
	config, format, err := image.DecodeConfig(bytes.NewReader(content))
	if err != nil || (format != "jpeg" && format != "png") || config.Width <= 0 || config.Height <= 0 || int64(config.Width)*int64(config.Height) > 24000000 {
		return domain.Message{}, domain.ErrInvalidMessage
	}
	locked, err := service.history.IsLocked(ctx, roomID)
	if err != nil {
		return domain.Message{}, fmt.Errorf("check chat room lock: %w", err)
	}
	if locked {
		return domain.Message{}, domain.ErrRoomLocked
	}
	member, err := service.history.IsMember(ctx, roomID, userID)
	if err != nil {
		return domain.Message{}, fmt.Errorf("check chat room membership: %w", err)
	}
	if !member {
		return domain.Message{}, domain.ErrForbidden
	}
	key, err := service.images.Store(ctx, content)
	if err != nil {
		return domain.Message{}, fmt.Errorf("store chat picture: %w", err)
	}
	message := domain.Message{ID: event.NewID(), RoomID: roomID, SenderID: userID, ImageKey: key, CreatedAt: time.Now().UTC().Format(time.RFC3339Nano)}
	if err := service.Relay(ctx, message); err != nil {
		cleanupContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
		defer cancel()
		if cleanupErr := service.images.Delete(cleanupContext, key); cleanupErr != nil {
			service.log().WarnContext(ctx, "remove rejected chat picture failed", "error", cleanupErr)
		}
		return domain.Message{}, err
	}
	return message, nil
}

func (service *Service) Image(ctx context.Context, roomID, userID, messageID string) ([]byte, string, error) {
	messageID = strings.TrimSpace(messageID)
	if messageID == "" {
		return nil, "", domain.ErrForbidden
	}
	allowed, err := service.CanReadRoom(ctx, roomID, userID)
	if err != nil {
		return nil, "", err
	}
	if !allowed {
		return nil, "", domain.ErrForbidden
	}
	message, found, err := service.history.FindMessage(ctx, roomID, messageID)
	if err != nil {
		return nil, "", fmt.Errorf("load chat message: %w", err)
	}
	if !found || message.ImageKey == "" {
		return nil, "", domain.ErrForbidden
	}
	if service.images == nil {
		return nil, "", domain.ErrRoomUnavailable
	}
	content, err := service.images.Read(ctx, message.ImageKey, MaxImageBytes)
	if err != nil {
		return nil, "", err
	}
	return content, http.DetectContentType(content), nil
}

func (service *Service) MarkRead(ctx context.Context, roomID, userID, messageID string) error {
	messageID = strings.TrimSpace(messageID)
	if messageID == "" {
		return domain.ErrInvalidMessage
	}
	allowed, err := service.CanReadRoom(ctx, roomID, userID)
	if err != nil {
		return err
	}
	if !allowed {
		return domain.ErrForbidden
	}
	message, found, err := service.history.FindMessage(ctx, roomID, messageID)
	if err != nil {
		return fmt.Errorf("load chat message: %w", err)
	}
	if !found || message.SenderID == userID {
		return domain.ErrInvalidMessage
	}
	created, err := time.Parse(time.RFC3339Nano, message.CreatedAt)
	if err != nil {
		return domain.ErrInvalidMessage
	}
	through := created.UTC().Format("2006-01-02T15:04:05.000000000Z")
	if err := service.history.MarkRead(ctx, roomID, userID, through); err != nil {
		return fmt.Errorf("save chat receipt: %w", err)
	}
	if service.events != nil {
		envelope, err := event.New(event.NewID(), event.ChatMessagesRead, time.Now().UTC(), event.Scope{RoomID: roomID}, map[string]any{"sender_id": userID, "read_through": through})
		if err != nil {
			return err
		}
		publishCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), _chatEventPublishTimeout)
		err = service.events.Publish(publishCtx, envelope)
		cancel()
		if err != nil {
			service.log().WarnContext(ctx, "publish chat receipt failed", "error", err)
		}
	}
	return nil
}
