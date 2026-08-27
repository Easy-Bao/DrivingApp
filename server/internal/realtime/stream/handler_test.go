package stream

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	"github.com/gorilla/websocket"
)

type authenticatorStub struct {
	identity security.Identity
	err      error
}

func (stub authenticatorStub) VerifyIdentity(string) (security.Identity, error) {
	return stub.identity, stub.err
}

func TestHandlerStreamsEventsOnlyToTheVerifiedIdentity(t *testing.T) {
	hub := NewHub()
	handler := NewHandler(hub, authenticatorStub{identity: security.Identity{Subject: "7", Role: "driver"}}, nil)
	server := httptest.NewServer(handler)
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
	server := httptest.NewServer(handler)
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
