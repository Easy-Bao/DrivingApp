package realtime_test

import (
	"context"
	"encoding/json"
	"testing"

	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	geodomain "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

type chatHistory struct {
	messages    []domain.Message
	passengerID string
	driverID    string
	locked      bool
}

type chatAssignmentLookup struct {
	assignment geodomain.RideAssignment
	found      bool
}

func (lookup chatAssignmentLookup) ForDriver(context.Context, string) (geodomain.RideAssignment, bool, error) {
	return lookup.assignment, lookup.found, nil
}

func (lookup chatAssignmentLookup) ForRide(context.Context, string) (geodomain.RideAssignment, bool, error) {
	return lookup.assignment, lookup.found, nil
}

type historicalChatAssignmentLookup struct {
	assignment geodomain.RideAssignment
	found      bool
}

func (lookup historicalChatAssignmentLookup) ForRide(context.Context, string) (geodomain.RideAssignment, bool, error) {
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
	service := usecase.NewService(chatadapter.NewHub(), history)

	if err := service.CreateRoom(
		context.Background(),
		"ride-1",
		"passenger-2",
		"driver-2",
	); err != domain.ErrRoomConflict {
		t.Fatalf("create room error = %v, want %v", err, domain.ErrRoomConflict)
	}
	if history.passengerID != "passenger-1" || history.driverID != "driver-1" {
		t.Fatalf("room participants changed to %q/%q", history.passengerID, history.driverID)
	}
}

func TestChatCreateRoomRequiresTheAssignedRideParticipants(t *testing.T) {
	history := &chatHistory{}
	service := usecase.NewService(chatadapter.NewHub(), history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: geodomain.RideAssignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
			},
			found: true,
		})

	if err := service.CreateRoom(
		context.Background(),
		"ride-1",
		"passenger-1",
		"driver-2",
	); err != domain.ErrForbidden {
		t.Fatalf("create room error = %v, want %v", err, domain.ErrForbidden)
	}
	if err := service.CreateRoom(
		context.Background(),
		"ride-1",
		"passenger-1",
		"driver-1",
	); err != nil {
		t.Fatalf("assigned participants could not create room: %v", err)
	}
}

func TestChatCreateRoomFallsBackToAuthoritativeParticipants(t *testing.T) {
	history := &chatHistory{}
	service := usecase.NewService(chatadapter.NewHub(), history).
		WithRideAssignmentLookup(chatAssignmentLookup{found: false}).
		WithRideParticipantLookup(historicalChatAssignmentLookup{
			assignment: geodomain.RideAssignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
			},
			found: true,
		})

	if err := service.CreateRoom(
		context.Background(),
		"ride-1",
		"passenger-1",
		"driver-1",
	); err != nil {
		t.Fatalf("historical participants could not create room: %v", err)
	}
}

func TestChatRelayRejectsResolvedRoom(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1", locked: true}
	service := usecase.NewService(chatadapter.NewHub(), history)

	err := service.Relay(context.Background(), domain.Message{
		RoomID:   "ride-1",
		SenderID: "driver-1",
		Body:     "This message must not be stored.",
	})
	if err != domain.ErrRoomLocked {
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
	hub := chatadapter.NewHub()
	history := &chatHistory{}
	service := usecase.NewService(hub, history)

	if err := service.Relay(context.Background(), domain.Message{RoomID: "ride-1", SenderID: "7", Body: "hello"}); err != nil {
		t.Fatal(err)
	}
	if len(history.messages) != 1 || history.messages[0].Body != "hello" {
		t.Fatalf("persisted messages = %#v", history.messages)
	}
}

func TestChatRelayPublishesPassengerScopedNotification(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	events := &chatEventPublisher{}
	service := usecase.NewService(chatadapter.NewHub(), history).
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
