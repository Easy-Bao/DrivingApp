package realtime_test

import (
	"context"
	"testing"

	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
)

type chatHistory struct {
	messages []domain.Message
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

func TestChatRelayPersistsBeforeBroadcasting(t *testing.T) {
	hub := chatadapter.NewHub()
	history := &chatHistory{}
	service := usecase.NewService(hub, history)

	if err := service.Relay(domain.Message{RoomID: "ride-1", SenderID: "7", Body: "hello"}); err != nil {
		t.Fatal(err)
	}
	if len(history.messages) != 1 || history.messages[0].Body != "hello" {
		t.Fatalf("persisted messages = %#v", history.messages)
	}
}
