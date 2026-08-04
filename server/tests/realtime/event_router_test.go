package realtime_test

import (
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
)

type eventSink struct{ called bool }

func (sink *eventSink) Handle([]byte) error { sink.called = true; return nil }

func TestEventRouterDispatchesByBoundedContext(t *testing.T) {
	sink := &eventSink{}
	router := ws.NewEventRouter()
	router.Register("CHAT_MESSAGE", sink)
	if err := router.Handle([]byte(`{"type":"CHAT_MESSAGE","room_id":"room-1"}`)); err != nil {
		t.Fatalf("dispatch failed: %v", err)
	}
	if !sink.called {
		t.Fatal("chat event was not dispatched")
	}
}
