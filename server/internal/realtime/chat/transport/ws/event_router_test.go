package ws_test

import (
	"context"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/ws"
)

type eventSink struct{ called bool }

func (sink *eventSink) Handle(context.Context, []byte) error { sink.called = true; return nil }

func TestEventRouterDispatchesByBoundedContext(t *testing.T) {
	sink := &eventSink{}
	router := ws.NewEventRouter()
	router.Register("CHAT_MESSAGE", sink)
	if err := router.Handle(context.Background(), []byte(`{"type":"CHAT_MESSAGE","room_id":"room-1"}`)); err != nil {
		t.Fatalf("dispatch failed: %v", err)
	}
	if !sink.called {
		t.Fatal("chat event was not dispatched")
	}
}

func TestEventRouterDispatchesLegacyChatMessageType(t *testing.T) {
	sink := &eventSink{}
	router := ws.NewEventRouter()
	router.Register("message", sink)
	if err := router.Handle(context.Background(), []byte(`{"type":"message","room_id":"room-1"}`)); err != nil {
		t.Fatalf("dispatch failed: %v", err)
	}
	if !sink.called {
		t.Fatal("legacy chat event was not dispatched")
	}
}
