package ws

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gorilla/websocket"
)

type authenticatorStub struct{}

func (authenticatorStub) Verify(string) (string, error) { return "7", nil }

type roomAuthorizerStub struct{}

func (roomAuthorizerStub) CanAccessRoom(context.Context, string, string) (bool, error) {
	return true, nil
}

type rejectingSinkStub struct{}

func (rejectingSinkStub) Handle(context.Context, []byte) error {
	return errors.New("room locked")
}

func TestChatWebSocketOriginPolicy(t *testing.T) {
	handler := NewHandler(NewHub(), nil).WithAllowedOrigins([]string{"https://app.example"})

	nativeRequest := httptest.NewRequest("GET", "/api/v1/chat/ws", nil)
	if !handler.originAllowed(nativeRequest) {
		t.Fatal("native client without an Origin header was rejected")
	}

	allowedRequest := httptest.NewRequest("GET", "/api/v1/chat/ws", nil)
	allowedRequest.Header.Set("Origin", "https://app.example")
	if !handler.originAllowed(allowedRequest) {
		t.Fatal("configured browser origin was rejected")
	}

	untrustedRequest := httptest.NewRequest("GET", "/api/v1/chat/ws", nil)
	untrustedRequest.Header.Set("Origin", "https://untrusted.example")
	if handler.originAllowed(untrustedRequest) {
		t.Fatal("untrusted browser origin was accepted")
	}
}

func TestChatWebSocketRejectsNonChatEvents(t *testing.T) {
	if validEvent([]byte(`{"type":"LOCATION_UPDATE"}`)) {
		t.Fatal("chat socket accepted a location event")
	}
	if validEvent([]byte(`{"type":"BID_CREATED"}`)) {
		t.Fatal("chat socket accepted a bid event")
	}
	if !validEvent([]byte(`{"type":"message"}`)) {
		t.Fatal("chat socket rejected a chat event")
	}
	if !validEvent([]byte(`{"type":"typing","is_typing":true}`)) {
		t.Fatal("chat socket rejected a typing event")
	}
	if validEvent([]byte(`{"type":"typing","is_typing":"true"}`)) {
		t.Fatal("chat socket accepted a malformed typing event")
	}
}

func TestEnrichChatEventCanonicalizesTypingIdentity(t *testing.T) {
	enriched := enrichChatEvent(
		[]byte(`{"type":"typing","isTyping":true,"sender_id":"attacker"}`),
		"303",
		"7",
	)
	if enriched == nil {
		t.Fatal("typing event was rejected")
	}
	var event map[string]any
	if err := json.Unmarshal(enriched, &event); err != nil {
		t.Fatal(err)
	}
	if event["room_id"] != "303" || event["sender_id"] != "7" || event["is_typing"] != true {
		t.Fatalf("enriched typing event = %#v", event)
	}
	if _, exists := event["isTyping"]; exists {
		t.Fatalf("legacy typing key was not removed: %#v", event)
	}
}

func TestChatWebSocketDoesNotBroadcastRejectedMessages(t *testing.T) {
	handler := NewHandlerWithSink(
		NewHub(),
		authenticatorStub{},
		rejectingSinkStub{},
		roomAuthorizerStub{},
	)
	server := httptest.NewServer(handler)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "/api/v1/chat/ws?roomId=303"
	connection, response, err := websocket.DefaultDialer.Dial(
		url,
		http.Header{"Authorization": []string{"Bearer valid"}},
	)
	if err != nil {
		if response != nil {
			t.Fatalf("dial status = %d, error = %v", response.StatusCode, err)
		}
		t.Fatal(err)
	}
	defer connection.Close()

	if err := connection.WriteJSON(map[string]string{"type": "message", "text": "blocked"}); err != nil {
		t.Fatal(err)
	}
	var reply map[string]string
	if err := connection.ReadJSON(&reply); err != nil {
		t.Fatal(err)
	}
	if reply["error"] != "event rejected" {
		t.Fatalf("reply = %#v", reply)
	}
}

func TestQueueMessageStopsWhenWriterHasExited(t *testing.T) {
	done := make(chan struct{})
	close(done)
	messages := make(chan []byte)

	if queueMessage(messages, done, []byte(`{"error":"closed"}`)) {
		t.Fatal("queued a message after the writer exited")
	}
}
