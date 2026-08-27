package ws

import (
	"context"
	"testing"
	"time"

	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
)

type roomRepositoryStub struct {
	message domain.Message
}

func (*roomRepositoryStub) CreateRoom(context.Context, string, string, string) error { return nil }
func (stub *roomRepositoryStub) Append(_ context.Context, message domain.Message) error {
	stub.message = message
	return nil
}
func (*roomRepositoryStub) Messages(context.Context, string) ([]domain.Message, error) {
	return nil, nil
}
func (*roomRepositoryStub) Resolve(context.Context, string) error { return nil }
func (*roomRepositoryStub) RoomParticipants(context.Context, string) (string, string, error) {
	return "7", "8", nil
}
func (*roomRepositoryStub) IsMember(context.Context, string, string) (bool, error) {
	return true, nil
}
func (*roomRepositoryStub) IsLocked(context.Context, string) (bool, error) { return false, nil }

func TestEventHandlerKeepsServerIdentityAndTimestamp(t *testing.T) {
	history := &roomRepositoryStub{}
	handler := NewEventHandler(usecase.NewChatService(chatadapter.NewHub(), history))
	before := time.Now().UTC()

	err := handler.Handle(context.Background(), []byte(`{
		"type":"message",
		"room_id":"303",
		"sender_id":"7",
		"senderId":"attacker",
		"text":"hello",
		"created_at":"2000-01-01T00:00:00Z",
		"createdAt":"2099-01-01T00:00:00Z"
	}`))
	if err != nil {
		t.Fatal(err)
	}
	if history.message.SenderID != "7" || history.message.Body != "hello" {
		t.Fatalf("stored message = %#v", history.message)
	}
	createdAt, err := time.Parse(time.RFC3339Nano, history.message.CreatedAt)
	if err != nil || createdAt.Before(before) || createdAt.After(time.Now().UTC().Add(time.Second)) {
		t.Fatalf("server timestamp = %q, error = %v", history.message.CreatedAt, err)
	}
}
