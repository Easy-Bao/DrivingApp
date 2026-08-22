package usecase

import (
	"context"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	geodomain "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

const (
	maxRoomIDBytes      = 128
	maxParticipantBytes = 128
	maxMessageBytes     = 4096
)

type Service struct {
	publisher              domain.Publisher
	history                domain.RoomRepository
	events                 EventPublisher
	assignments            geodomain.RideAssignmentLookup
	historicalParticipants RideParticipantLookup
}

type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}

type RideParticipantLookup interface {
	ForRide(ctx context.Context, rideID string) (geodomain.RideAssignment, bool, error)
}

func NewService(publisher domain.Publisher, history domain.RoomRepository) *Service {
	return &Service{publisher: publisher, history: history}
}

func (service *Service) WithEventPublisher(publisher EventPublisher) *Service {
	service.events = publisher
	return service
}

func (service *Service) WithRideAssignmentLookup(
	lookup geodomain.RideAssignmentLookup,
) *Service {
	service.assignments = lookup
	return service
}

func (service *Service) WithRideParticipantLookup(
	lookup RideParticipantLookup,
) *Service {
	service.historicalParticipants = lookup
	return service
}
func (service *Service) Relay(ctx context.Context, message domain.Message) error {
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

func (service *Service) publishRealtimeMessage(ctx context.Context, message domain.Message) {
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

func (service *Service) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	if !validRoomID(roomID) || !validParticipantID(passengerID) || !validParticipantID(driverID) {
		return domain.ErrInvalidRoom
	}
	if service.history == nil {
		return domain.ErrRoomUnavailable
	}
	existingPassengerID, existingDriverID, err := service.history.RoomParticipants(ctx, roomID)
	if err != nil {
		return err
	}
	if (existingPassengerID != "" || existingDriverID != "") &&
		(existingPassengerID != passengerID || existingDriverID != driverID) {
		return domain.ErrRoomConflict
	}
	if existingPassengerID != "" || existingDriverID != "" {
		locked, err := service.history.IsLocked(ctx, roomID)
		if err != nil {
			return err
		}
		if locked {
			return domain.ErrRoomLocked
		}
	}
	if existingPassengerID == "" && existingDriverID == "" {
		if err := service.authorizeRoomCreation(ctx, roomID, passengerID, driverID); err != nil {
			return err
		}
	}
	return service.history.CreateRoom(ctx, roomID, passengerID, driverID)
}

func (service *Service) authorizeRoomCreation(
	ctx context.Context,
	roomID, passengerID, driverID string,
) error {
	if service.assignments != nil {
		assignment, found, err := service.assignments.ForRide(ctx, roomID)
		if err != nil {
			return domain.ErrRoomUnavailable
		}
		if found {
			if assignment.PassengerID != passengerID || assignment.DriverID != driverID {
				return domain.ErrForbidden
			}
			return nil
		}
	}

	if service.historicalParticipants != nil {
		assignment, found, err := service.historicalParticipants.ForRide(ctx, roomID)
		if err != nil {
			return domain.ErrRoomUnavailable
		}
		if found && assignment.PassengerID == passengerID && assignment.DriverID == driverID {
			return nil
		}
		return domain.ErrForbidden
	}

	return domain.ErrRoomUnavailable
}

func (service *Service) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if !validRoomID(roomID) {
		return nil, domain.ErrInvalidRoom
	}
	if service.history == nil {
		return nil, domain.ErrRoomUnavailable
	}
	return service.history.Messages(ctx, roomID)
}

func (service *Service) Resolve(ctx context.Context, roomID string) error {
	if !validRoomID(roomID) {
		return domain.ErrInvalidRoom
	}
	if service.history == nil {
		return domain.ErrRoomUnavailable
	}
	return service.history.Resolve(ctx, roomID)
}

func (service *Service) CanAccessRoom(ctx context.Context, roomID, userID string) (bool, error) {
	if !validRoomID(roomID) || !validParticipantID(userID) || service.history == nil {
		return false, nil
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

func (service *Service) MessagesForUser(ctx context.Context, roomID, userID string) ([]domain.Message, error) {
	if !service.hasAccess(ctx, roomID, userID) {
		return nil, domain.ErrForbidden
	}
	return service.Messages(ctx, roomID)
}

func (service *Service) ResolveForUser(ctx context.Context, roomID, userID string) error {
	if !service.hasAccess(ctx, roomID, userID) {
		return domain.ErrForbidden
	}
	return service.Resolve(ctx, roomID)
}

func (service *Service) hasAccess(ctx context.Context, roomID, userID string) bool {
	allowed, err := service.CanAccessRoom(ctx, roomID, userID)
	return err == nil && allowed
}

func validRoomID(value string) bool {
	return value != "" && len(value) <= maxRoomIDBytes && !strings.ContainsAny(value, "\r\n")
}

func validParticipantID(value string) bool {
	return value != "" && len(value) <= maxParticipantBytes && !strings.ContainsAny(value, "\r\n")
}
