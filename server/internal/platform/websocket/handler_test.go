package hub

import (
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/gorilla/websocket"
)

type authenticatorStub struct {
	identity security.Identity
	err      error
}

type testHTTPServer struct {
	URL    string
	server *http.Server
}

func (server *testHTTPServer) Close() error {
	return server.server.Close()
}

func newIPv4TestServer(t *testing.T, handler http.Handler) *testHTTPServer {
	t.Helper()

	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen for test server: %v", err)
	}
	httpServer := &http.Server{Handler: handler}
	go func() {
		_ = httpServer.Serve(listener)
	}()
	return &testHTTPServer{
		URL:    "http://" + listener.Addr().String(),
		server: httpServer,
	}
}

func (stub authenticatorStub) VerifyIdentity(string) (security.Identity, error) {
	return stub.identity, stub.err
}

func TestHandlerStreamsEventsOnlyToTheVerifiedIdentity(t *testing.T) {
	hub := NewHub()
	handler := NewHandler(hub, authenticatorStub{identity: security.Identity{Subject: "7", Role: "driver"}}, nil)
	server := newIPv4TestServer(t, handler)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http")
	connection, _, err := websocket.DefaultDialer.Dial(url, http.Header{"Authorization": []string{"Bearer valid"}})
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}
	defer connection.Close()

	envelope, err := event.New(
		"event-1",
		event.RideMatched,
		time.Now().UTC(),
		event.Scope{DriverID: "7"},
		map[string]any{"ride_id": "ride-1"},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	hub.Publish(envelope)

	_ = connection.SetReadDeadline(time.Now().Add(time.Second))
	var received event.Envelope
	if err := connection.ReadJSON(&received); err != nil {
		t.Fatalf("ReadJSON() error = %v", err)
	}
	if received.ID != envelope.ID || received.Scope.DriverID != "7" {
		t.Fatalf("received event = %#v", received)
	}
}

func TestHandlerStreamsOpenOffersToVerifiedDrivers(t *testing.T) {
	hub := NewHub()
	handler := NewHandler(hub, authenticatorStub{identity: security.Identity{Subject: "7", Role: "driver"}}, nil)
	server := newIPv4TestServer(t, handler)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http")
	connection, _, err := websocket.DefaultDialer.Dial(url, http.Header{"Authorization": []string{"Bearer valid"}})
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}
	defer connection.Close()

	envelope, err := event.New(
		"event-open-offer",
		event.RideOfferCreated,
		time.Now().UTC(),
		event.Scope{PassengerID: "9", DriverPool: true},
		map[string]any{"session_id": "31"},
	)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	hub.Publish(envelope)

	_ = connection.SetReadDeadline(time.Now().Add(time.Second))
	var received event.Envelope
	if err := connection.ReadJSON(&received); err != nil {
		t.Fatalf("ReadJSON() error = %v", err)
	}
	if received.ID != envelope.ID || !received.Scope.DriverPool {
		t.Fatalf("received event = %#v", received)
	}
}

func TestHandlerRejectsUnauthenticatedOrUnsupportedRoles(t *testing.T) {
	hub := NewHub()

	unauthenticated := NewHandler(hub, authenticatorStub{err: errors.New("invalid")}, nil)
	request := httptest.NewRequest(http.MethodGet, "/api/v1/realtime/ws", nil)
	request.Header.Set("Authorization", "Bearer invalid")
	response := httptest.NewRecorder()
	unauthenticated.ServeHTTP(response, request)
	if response.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated status = %d, want %d", response.Code, http.StatusUnauthorized)
	}

	unsupportedRole := NewHandler(hub, authenticatorStub{identity: security.Identity{Subject: "7", Role: "admin"}}, nil)
	request = httptest.NewRequest(http.MethodGet, "/api/v1/realtime/ws", nil)
	request.Header.Set("Authorization", "Bearer valid")
	response = httptest.NewRecorder()
	unsupportedRole.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("unsupported role status = %d, want %d", response.Code, http.StatusForbidden)
	}
}

func TestHandlerClosesConnectionForOversizedClientMessage(t *testing.T) {
	hub := NewHub()
	handler := NewHandler(hub, authenticatorStub{identity: security.Identity{Subject: "7", Role: "driver"}}, nil)
	server := newIPv4TestServer(t, handler)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http")
	connection, _, err := websocket.DefaultDialer.Dial(url, http.Header{"Authorization": []string{"Bearer valid"}})
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}
	defer connection.Close()

	oversizedMessage := strings.Repeat("x", maximumMessageSize+1)
	if err := connection.WriteMessage(websocket.TextMessage, []byte(oversizedMessage)); err != nil {
		t.Fatalf("WriteMessage() error = %v", err)
	}
	if err := connection.SetReadDeadline(time.Now().Add(time.Second)); err != nil {
		t.Fatalf("SetReadDeadline() error = %v", err)
	}
	if _, _, err := connection.ReadMessage(); err == nil {
		t.Fatal("ReadMessage() succeeded after an oversized client frame")
	}
}

func TestHandlerScavengesSubscriptionAfterAbruptSocketDisconnect(t *testing.T) {
	hub := NewHub()
	handler := NewHandler(
		hub,
		authenticatorStub{identity: security.Identity{Subject: "7", Role: "driver"}},
		nil,
	)
	server := newIPv4TestServer(t, handler)
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http")
	connection, _, err := websocket.DefaultDialer.Dial(
		url,
		http.Header{"Authorization": []string{"Bearer valid"}},
	)
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}

	if got := hub.topicSubscriberCount("driver:7"); got != 1 {
		t.Fatalf("subscriber count after dial = %d, want 1", got)
	}
	if err := connection.UnderlyingConn().Close(); err != nil {
		t.Fatalf("close underlying connection: %v", err)
	}

	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		if hub.topicSubscriberCount("driver:7") == 0 {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("subscription remained after abrupt disconnect")
}
