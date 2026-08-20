package realtime_test

import (
	"context"
	"encoding/json"
	"testing"

	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

type chatHistory struct {
	messages    []domain.Message
	passengerID string
	driverID    string
}

func (history *chatHistory) CreateRoom(context.Context, string, string, string) error { return nil }
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
