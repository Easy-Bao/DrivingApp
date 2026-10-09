package ws_test

import (
	"fmt"
	"sync"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/chat/transport/ws"
)

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
