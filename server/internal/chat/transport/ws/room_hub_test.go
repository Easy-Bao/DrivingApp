package ws_test

import (
	"encoding/json"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/ws"
	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

func TestRoomHubPublishesChatMessageEventInChatWireFormat(t *testing.T) {
	hub := ws.NewRoomHub()
	messages := hub.Add("passenger-1", "room-1")
	defer hub.Remove("passenger-1", messages)

	envelope, err := events.New(
		"event-1",
		events.ChatMessageCreated,
		time.Date(2026, time.October, 10, 10, 0, 0, 0, time.UTC),
		events.Scope{RoomID: "room-1", PassengerID: "passenger-1", DriverID: "driver-1"},
		map[string]any{
			"sender_id":  "driver-1",
			"text":       "On my way",
			"created_at": "2026-10-10T10:00:00Z",
		},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	hub.Publish(envelope)
	select {
	case rawMessage := <-messages:
		var message map[string]string
		if err := json.Unmarshal(rawMessage, &message); err != nil {
			t.Fatalf("decode chat websocket message: %v", err)
		}
		if message["type"] != "message" || message["id"] != "event-1" ||
			message["room_id"] != "room-1" || message["sender_id"] != "driver-1" ||
			message["text"] != "On my way" || message["created_at"] != "2026-10-10T10:00:00Z" {
			t.Fatalf("chat websocket message = %#v", message)
		}
	default:
		t.Fatal("chat room did not receive its persisted message event")
	}
}

func TestHubBroadcastsOnlyWithinTheSubscribedRoom(t *testing.T) {
	hub := ws.NewRoomHub()
	roomOne := hub.Add("user-1", "room-1")
	roomTwo := hub.Add("user-2", "room-2")
	hub.Broadcast("room-1", []byte("private message"))
	select {
	case message := <-roomOne:
		if string(message) != "private message" {
			t.Fatalf("room one received %q", message)
		}
	default:
		t.Fatal("room one did not receive its message")
	}
	select {
	case message := <-roomTwo:
		t.Fatalf("room two received leaked message %q", message)
	default:
	}
	hub.Remove("user-1", roomOne)
	hub.Remove("user-2", roomTwo)
}

func TestRoomHubBurst(t *testing.T) {
	hub := ws.NewRoomHub()
	messages := hub.Add("user-1", "room-1")
	defer hub.Remove("user-1", messages)

	const totalMessages = 30
	var publishers sync.WaitGroup
	for i := 0; i < totalMessages; i++ {
		message := []byte(fmt.Sprintf("message-%d", i))
		publishers.Add(1)
		go func(message []byte) {
			defer publishers.Done()
			hub.Broadcast("room-1", message)
		}(message)
	}
	publishers.Wait()

	receivedMessages := make(map[string]struct{}, totalMessages)
	for len(receivedMessages) < totalMessages {
		select {
		case message, ok := <-messages:
			if !ok {
				t.Fatal("client channel closed before the burst was delivered")
			}
			got := string(message)
			if _, exists := receivedMessages[got]; exists {
				t.Fatalf("received duplicate message %q", got)
			}
			receivedMessages[got] = struct{}{}
		default:
			t.Fatalf("received %d of %d messages", len(receivedMessages), totalMessages)
		}
	}
	for expected := 0; expected < totalMessages; expected++ {
		expectedMessage := fmt.Sprintf("message-%d", expected)
		if _, exists := receivedMessages[expectedMessage]; !exists {
			t.Fatalf("message %q was not delivered", expectedMessage)
		}
	}
}

func TestRoomHubClosesSlowClientWhenQueueIsFull(t *testing.T) {
	hub := ws.NewRoomHub()
	messages := hub.Add("user-1", "room-1")

	for i := 0; i <= cap(messages); i++ {
		hub.Broadcast("room-1", []byte(fmt.Sprintf("message-%d", i)))
	}

	delivered := 0
	for range messages {
		delivered++
	}
	if delivered != cap(messages) {
		t.Fatalf("messages delivered before slow client closed = %d, want %d", delivered, cap(messages))
	}
}
