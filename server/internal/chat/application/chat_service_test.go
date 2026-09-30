package application_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"
	chatports "github.com/Easy-Bao/DrivingApp/server/internal/chat/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

type chatHistory struct {
	messages    []domain.Message
	passengerID string
	driverID    string
	locked      bool
}

func newChatService(history chatports.RoomStore) *application.ChatService {
	return application.NewChatService(application.ChatServiceDependencies{History: history})
}

type chatAssignmentLookup struct {
	assignment assignment.Assignment
	found      bool
}

func (lookup chatAssignmentLookup) ForDriver(context.Context, string) ([]assignment.Assignment, error) {
	if !lookup.found {
		return nil, nil
	}
	return []assignment.Assignment{lookup.assignment}, nil
}

func (lookup chatAssignmentLookup) ForRide(context.Context, string) (assignment.Assignment, bool, error) {
	return lookup.assignment, lookup.found, nil
}

func (history *chatHistory) CreateRoom(
	_ context.Context,
	_ string,
	passengerID string,
	driverID string,
) error {
	history.passengerID = passengerID
	history.driverID = driverID
	return nil
}
func (history *chatHistory) Append(_ context.Context, message domain.Message) error {
	history.messages = append(history.messages, message)
	return nil
}
func (history *chatHistory) Messages(context.Context, string) ([]domain.Message, error) {
	return history.messages, nil
}
func (history *chatHistory) Resolve(context.Context, string) error { return nil }
func (history *chatHistory) RoomParticipants(context.Context, string) (string, string, error) {
	return history.passengerID, history.driverID, nil
}
func (history *chatHistory) IsMember(context.Context, string, string) (bool, error) {
	return true, nil
}
func (history *chatHistory) IsLocked(context.Context, string) (bool, error) {
	return history.locked, nil
}

func TestChatCreateRoomDoesNotReplaceParticipants(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID: "ride-1", PassengerID: "passenger-1", DriverID: "driver-1", Status: "assigned",
			},
			found: true,
		})

	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"passenger-2",
	); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("create room error = %v, want %v", err, domain.ErrForbidden)
	}
	if history.passengerID != "passenger-1" || history.driverID != "driver-1" {
		t.Fatalf("room participants changed to %q/%q", history.passengerID, history.driverID)
	}
}

func TestChatCreateRoomRequiresTheAssignedRideParticipants(t *testing.T) {
	history := &chatHistory{}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
				Status:      "assigned",
				ContactOpen: true,
			},
			found: true,
		})

	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"driver-2",
	); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("create room error = %v, want %v", err, domain.ErrForbidden)
	}
	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"passenger-1",
	); err != nil {
		t.Fatalf("assigned participants could not create room: %v", err)
	}
}

func TestChatCreateRoomUsesAuthoritativeParticipants(t *testing.T) {
	history := &chatHistory{}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
				Status:      "completed",
				ContactOpen: true,
			},
			found: true,
		})

	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"driver-1",
	); err != nil {
		t.Fatalf("authoritative participant could not create room: %v", err)
	}
	if history.passengerID != "passenger-1" || history.driverID != "driver-1" {
		t.Fatalf("created room participants = %q/%q", history.passengerID, history.driverID)
	}
}

func TestChatRelayRejectsResolvedRoom(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1", locked: true}
	service := newChatService(history)

	err := service.Relay(context.Background(), domain.Message{
		RoomID:   "ride-1",
		SenderID: "driver-1",
		Body:     "This message must not be stored.",
	})
	if !errors.Is(err, domain.ErrRoomLocked) {
		t.Fatalf("relay error = %v, want %v", err, domain.ErrRoomLocked)
	}
	if len(history.messages) != 0 {
		t.Fatalf("resolved room stored %d messages", len(history.messages))
	}
}

type chatEventPublisher struct {
	events []event.Envelope
}

func (publisher *chatEventPublisher) Publish(_ context.Context, envelope event.Envelope) error {
	publisher.events = append(publisher.events, envelope)
	return nil
}

func TestChatRelayPersistsBeforeBroadcasting(t *testing.T) {
	history := &chatHistory{}
	service := newChatService(history)

	err := service.Relay(
		context.Background(),
		domain.Message{RoomID: "ride-1", SenderID: "7", Body: "hello"},
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(history.messages) != 1 || history.messages[0].Body != "hello" {
		t.Fatalf("persisted messages = %#v", history.messages)
	}
}

func TestChatRelayPublishesPassengerScopedNotification(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	events := &chatEventPublisher{}
	service := newChatService(history).
		WithEventPublisher(events)

	if err := service.Relay(context.Background(), domain.Message{
		RoomID:    "ride-1",
		SenderID:  "driver-1",
		Body:      "I am at the pickup point.",
		CreatedAt: "2026-08-20T08:00:00Z",
	}); err != nil {
		t.Fatal(err)
	}
	if len(events.events) != 1 {
		t.Fatalf("published events = %d, want 1", len(events.events))
	}
	envelope := events.events[0]
	if envelope.Type != event.ChatMessageCreated || envelope.Scope.PassengerID != "passenger-1" {
		t.Fatalf("event routing = %#v, want chat notification for passenger-1", envelope)
	}
	var payload map[string]string
	if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
		t.Fatal(err)
	}
	if payload["sender_id"] != "driver-1" || payload["text"] != "I am at the pickup point." {
		t.Fatalf("event payload = %#v", payload)
	}
}

func TestChatMessagesReturnsACopy(t *testing.T) {
	history := &chatHistory{messages: []domain.Message{{RoomID: "ride-1", Body: "original"}}}
	service := newChatService(history)

	messages, err := service.Messages(context.Background(), "ride-1")
	if err != nil {
		t.Fatalf("Messages() error = %v", err)
	}
	messages[0].Body = "mutated"
	if history.messages[0].Body != "original" {
		t.Fatalf("history was mutated through returned messages: %#v", history.messages)
	}
}
