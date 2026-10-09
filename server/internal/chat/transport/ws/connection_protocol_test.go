package ws

import (
	"context"
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"strings"
	"testing"
	"time"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/websocket"
	"github.com/gorilla/websocket"
)

type protocolAuthenticatorStub struct{ identity security.Identity }

func (stub protocolAuthenticatorStub) VerifyIdentity(string) (security.Identity, error) {
	return stub.identity, nil
}

type protocolRoomAuthorizerStub struct {
	allowed bool
	err     error
}

func (stub protocolRoomAuthorizerStub) CanAccessRoom(context.Context, string, string) (bool, error) {
	return stub.allowed, stub.err
}

type protocolEventSinkStub struct {
	messages chan []byte
	err      error
}

func (stub protocolEventSinkStub) Handle(_ context.Context, message []byte) error {
	if stub.err != nil {
		return stub.err
	}
	if stub.messages != nil {
		stub.messages <- append([]byte(nil), message...)
	}
	return nil
}

type protocolTestServer struct {
	url    string
	server *http.Server
}

func (server *protocolTestServer) Close() error {
	return server.server.Close()
}

func newProtocolTestServer(t *testing.T, handler http.Handler) *protocolTestServer {
	t.Helper()
	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen for websocket test server: %v", err)
	}
	server := &http.Server{Handler: handler}
	go func() { _ = server.Serve(listener) }()
	return &protocolTestServer{url: "http://" + listener.Addr().String(), server: server}
}

func TestConnectionProtocolResolvesOnlyAuthorizedRoomTopics(t *testing.T) {
	identity := security.Identity{Subject: "7", Role: "passenger"}

	tests := []struct {
		name       string
		path       string
		authorizer RoomAuthorizer
		wantTopic  string
		wantStatus int
	}{
		{
			name:       "authorized room",
			path:       "/api/v1/chat/ws?roomId=ride-1",
			authorizer: protocolRoomAuthorizerStub{allowed: true},
			wantTopic:  "room:ride-1",
		},
		{
			name:       "missing room",
			path:       "/api/v1/chat/ws",
			authorizer: protocolRoomAuthorizerStub{allowed: true},
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "invalid room identifier",
			path:       "/api/v1/chat/ws?roomId=%20ride-1",
			authorizer: protocolRoomAuthorizerStub{allowed: true},
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "room access denied",
			path:       "/api/v1/chat/ws?roomId=ride-1",
			authorizer: protocolRoomAuthorizerStub{allowed: false},
			wantStatus: http.StatusForbidden,
		},
		{
			name:       "room authorizer unavailable",
			path:       "/api/v1/chat/ws?roomId=ride-1",
			wantStatus: http.StatusServiceUnavailable,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			protocol := NewConnectionProtocol(nil, test.authorizer)
			request, err := http.NewRequest(http.MethodGet, test.path, nil)
			if err != nil {
				t.Fatal(err)
			}
			topics, err := protocol.ResolveTopics(context.Background(), request, identity)
			if test.wantStatus != 0 {
				var handshakeError *websockethub.HandshakeError
				if !errors.As(err, &handshakeError) {
					t.Fatalf("ResolveTopics() error = %v, want handshake error", err)
				}
				if handshakeError.StatusCode != test.wantStatus {
					t.Fatalf("handshake status = %d, want %d", handshakeError.StatusCode, test.wantStatus)
				}
				return
			}
			if err != nil {
				t.Fatalf("ResolveTopics() error = %v", err)
			}
			if len(topics) != 1 || topics[0] != test.wantTopic {
				t.Fatalf("ResolveTopics() = %#v, want [%q]", topics, test.wantTopic)
			}
		})
	}
}

func TestConnectionProtocolCanonicalizesTypingIdentity(t *testing.T) {
	messages := make(chan []byte, 1)
	protocol := NewConnectionProtocol(protocolEventSinkStub{messages: messages}, nil)
	request, err := http.NewRequest(http.MethodGet, "/api/v1/chat/ws?roomId=303", nil)
	if err != nil {
		t.Fatal(err)
	}
	identity := security.Identity{Subject: "7", Role: "driver"}

	reply, err := protocol.HandleMessage(
		context.Background(),
		request,
		identity,
		true,
		[]byte(`{"type":"typing","isTyping":true,"sender_id":"attacker","room_id":"other"}`),
	)
	if err != nil || len(reply) != 0 {
		t.Fatalf("HandleMessage() = (%q, %v), want no reply and no error", reply, err)
	}

	var received map[string]any
	if err := json.Unmarshal(<-messages, &received); err != nil {
		t.Fatal(err)
	}
	if received["room_id"] != "303" || received["sender_id"] != "7" || received["is_typing"] != true {
		t.Fatalf("canonical typing event = %#v", received)
	}
	if _, exists := received["isTyping"]; exists {
		t.Fatalf("legacy typing key remained: %#v", received)
	}
}

func TestConnectionProtocolRejectsInvalidAndFailedMessages(t *testing.T) {
	request, err := http.NewRequest(http.MethodGet, "/api/v1/chat/ws?roomId=303", nil)
	if err != nil {
		t.Fatal(err)
	}
	identity := security.Identity{Subject: "7", Role: "passenger"}

	tests := []struct {
		name     string
		protocol *ConnectionProtocol
		isText   bool
		message  []byte
		want     string
	}{
		{
			name:     "binary frame",
			protocol: NewConnectionProtocol(protocolEventSinkStub{}, nil),
			message:  []byte(`{"type":"message","text":"hello"}`),
			want:     `{"error":"invalid event"}`,
		},
		{
			name:     "unsupported event",
			protocol: NewConnectionProtocol(protocolEventSinkStub{}, nil),
			isText:   true,
			message:  []byte(`{"type":"location"}`),
			want:     `{"error":"invalid event"}`,
		},
		{
			name: "event service failure",
			protocol: NewConnectionProtocol(protocolEventSinkStub{
				err: errors.New("room is locked"),
			}, nil),
			isText:  true,
			message: []byte(`{"type":"message","text":"hello"}`),
			want:    `{"error":"event rejected"}`,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			reply, err := test.protocol.HandleMessage(context.Background(), request, identity, test.isText, test.message)
			if err != nil {
				t.Fatalf("HandleMessage() error = %v", err)
			}
			if string(reply) != test.want {
				t.Fatalf("HandleMessage() reply = %s, want %s", reply, test.want)
			}
		})
	}
}

func TestChatCompatibilityEndpointUsesSharedWebSocketEngine(t *testing.T) {
	hub := websockethub.NewHub()
	messages := make(chan []byte, 1)
	protocol := NewConnectionProtocol(
		protocolEventSinkStub{messages: messages},
		protocolRoomAuthorizerStub{allowed: true},
	)
	handler := websockethub.NewHandler(websockethub.HandlerDependencies{
		Hub:           hub,
		Authenticator: protocolAuthenticatorStub{identity: security.Identity{Subject: "7", Role: "driver"}},
		Protocol:      protocol,
	})
	server := newProtocolTestServer(t, handler)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.url, "http") + "/api/v1/chat/ws?roomId=303"
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

	envelope, err := event.New(
		"chat-event-1",
		event.ChatMessageCreated,
		time.Now().UTC(),
		event.Scope{RoomID: "303"},
		map[string]any{
			"sender_id":  "9",
			"text":       "On my way",
			"created_at": "2026-10-10T10:00:00Z",
		},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	hub.Publish(envelope)

	if err := connection.SetReadDeadline(time.Now().Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	var outbound map[string]any
	if err := connection.ReadJSON(&outbound); err != nil {
		t.Fatalf("read compatibility chat event: %v", err)
	}
	if outbound["type"] != "message" || outbound["id"] != "chat-event-1" ||
		outbound["room_id"] != "303" || outbound["sender_id"] != "9" || outbound["text"] != "On my way" {
		t.Fatalf("compatibility message = %#v", outbound)
	}

	if err := connection.WriteJSON(map[string]any{
		"type":      "typing",
		"is_typing": true,
		"sender_id": "attacker",
		"room_id":   "other",
	}); err != nil {
		t.Fatalf("write compatibility typing event: %v", err)
	}
	select {
	case rawMessage := <-messages:
		var inbound map[string]any
		if err := json.Unmarshal(rawMessage, &inbound); err != nil {
			t.Fatal(err)
		}
		if inbound["room_id"] != "303" || inbound["sender_id"] != "7" || inbound["is_typing"] != true {
			t.Fatalf("canonical inbound chat event = %#v", inbound)
		}
	case <-time.After(time.Second):
		t.Fatal("shared websocket engine did not forward chat input to the protocol")
	}
}
