package realtime_test

import (
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
)

func TestHubBroadcastsOnlyWithinTheSubscribedRoom(t *testing.T) {
	hub := ws.NewHub()
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
