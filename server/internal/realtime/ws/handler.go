package ws

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/gorilla/websocket"
)

type Handler struct {
	hub            *Hub
	authenticate   Authenticator
	sink           EventSink
	rooms          RoomAuthorizer
	allowedOrigins map[string]struct{}
	upgrader       websocket.Upgrader
}

type Authenticator interface {
	Verify(token string) (string, error)
}

type EventSink interface {
	Handle(ctx context.Context, message []byte) error
}

type RoomAuthorizer interface {
	CanAccessRoom(ctx context.Context, roomID, userID string) (bool, error)
}

func NewHandler(hub *Hub, authenticate Authenticator) *Handler {
	handler := &Handler{
		hub:            hub,
		authenticate:   authenticate,
		allowedOrigins: make(map[string]struct{}),
	}
	handler.upgrader = websocket.Upgrader{CheckOrigin: handler.originAllowed}
	return handler
}

func NewHandlerWithSink(hub *Hub, authenticate Authenticator, sink EventSink, rooms ...RoomAuthorizer) *Handler {
	handler := NewHandler(hub, authenticate)
	handler.sink = sink
	if len(rooms) > 0 {
		handler.rooms = rooms[0]
	}
	return handler
}

func (handler *Handler) WithAllowedOrigins(origins []string) *Handler {
	handler.allowedOrigins = make(map[string]struct{}, len(origins))
	for _, origin := range origins {
		if trimmed := strings.TrimSpace(origin); trimmed != "" {
			handler.allowedOrigins[trimmed] = struct{}{}
		}
	}
	return handler
}

func (handler *Handler) originAllowed(request *http.Request) bool {
	origin := strings.TrimSpace(request.Header.Get("Origin"))
	if origin == "" {
		return true
	}
	_, allowed := handler.allowedOrigins[origin]
	return allowed
}

func (handler *Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	token, ok := bearerToken(request.Header.Get("Authorization"))
	if !ok {
		http.Error(writer, "unauthorized", http.StatusUnauthorized)
		return
	}
	clientID, err := handler.authenticate.Verify(token)
	if err != nil || clientID == "" {
		http.Error(writer, "unauthorized", http.StatusUnauthorized)
		return
	}
	roomID := request.URL.Query().Get("roomId")
	if roomID == "" {
		http.Error(writer, "room id is required", http.StatusBadRequest)
		return
	}
	if handler.rooms != nil {
		allowed, accessErr := handler.rooms.CanAccessRoom(request.Context(), roomID, clientID)
		if accessErr != nil {
			http.Error(writer, "chat room unavailable", http.StatusServiceUnavailable)
			return
		}
		if !allowed {
			http.Error(writer, "chat room access denied", http.StatusForbidden)
			return
		}
	}
	connection, err := handler.upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return
	}
	defer connection.Close()

	connection.SetReadLimit(16 << 10)
	outbound := handler.hub.Add(clientID, roomID)
	defer handler.hub.Remove(clientID, outbound)

	go func() {
		for message := range outbound {
			_ = connection.WriteMessage(websocket.TextMessage, message)
		}
	}()

	for {
		messageType, message, readErr := connection.ReadMessage()
		if readErr != nil {
			return
		}
		if messageType != websocket.TextMessage || !validEvent(message) {
			_ = connection.WriteJSON(map[string]string{"error": "invalid event"})
			continue
		}
		eventMessage := message
		if eventMessage = enrichChatEvent(eventMessage, request.URL.Query().Get("roomId"), clientID); eventMessage == nil {
			_ = connection.WriteJSON(map[string]string{"error": "invalid chat event"})
			continue
		}
		if handler.sink != nil {
			_ = handler.sink.Handle(request.Context(), eventMessage)
		}
		if isChatEvent(eventMessage) {
			handler.hub.Broadcast(roomID, eventMessage)
		}
	}
}

func bearerToken(header string) (string, bool) {
	const prefix = "Bearer "
	if len(header) <= len(prefix) || !strings.HasPrefix(header, prefix) {
		return "", false
	}
	return header[len(prefix):], true
}

func isChatEvent(message []byte) bool {
	var event struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(message, &event) != nil {
		return false
	}
	return event.Type == "CHAT_MESSAGE" || event.Type == "message"
}

func validEvent(message []byte) bool {
	var event struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(message, &event) != nil {
		return false
	}
	switch event.Type {
	case "LOCATION_UPDATE", "CHAT_MESSAGE", "BID_CREATED", "message":
		return true
	default:
		return false
	}
}

func enrichChatEvent(message []byte, roomID, clientID string) []byte {
	var event map[string]any
	if json.Unmarshal(message, &event) != nil {
		return nil
	}
	if event["type"] != "CHAT_MESSAGE" && event["type"] != "message" {
		return message
	}
	if roomID == "" || clientID == "" {
		return nil
	}
	event["room_id"] = roomID
	event["sender_id"] = clientID
	return marshalEvent(event)
}

func marshalEvent(event map[string]any) []byte {
	message, err := json.Marshal(event)
	if err != nil {
		return nil
	}
	return message
}
