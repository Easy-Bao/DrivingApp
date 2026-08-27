package ws

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/gorilla/websocket"
)

const (
	chatPongWait  = 60 * time.Second
	chatPingEvery = 54 * time.Second
	chatWriteWait = 10 * time.Second
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
	if handler == nil || handler.hub == nil || handler.authenticate == nil {
		response.Error(writer, http.StatusServiceUnavailable, "Chat is temporarily unavailable. Please try again shortly.")
		return
	}
	token, ok := middleware.BearerToken(request.Header.Get("Authorization"))
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "Authentication is required. Please sign in again to continue.")
		return
	}
	clientID, err := handler.authenticate.Verify(token)
	if err != nil || clientID == "" {
		response.Error(writer, http.StatusUnauthorized, "Authentication is required. Please sign in again to continue.")
		return
	}
	roomID := request.URL.Query().Get("roomId")
	if roomID == "" {
		response.Error(writer, http.StatusBadRequest, "Please select a valid chat room.")
		return
	}
	if handler.rooms != nil {
		allowed, accessErr := handler.rooms.CanAccessRoom(request.Context(), roomID, clientID)
		if accessErr != nil {
			response.Error(writer, http.StatusServiceUnavailable, "Chat is temporarily unavailable. Please try again shortly.")
			return
		}
		if !allowed {
			response.Error(writer, http.StatusForbidden, "You do not have permission to access this chat.")
			return
		}
	}
	connection, err := handler.upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return
	}
	defer connection.Close()

	connection.SetReadLimit(16 << 10)
	if err := connection.SetReadDeadline(time.Now().Add(chatPongWait)); err != nil {
		return
	}
	connection.SetPongHandler(func(string) error {
		return connection.SetReadDeadline(time.Now().Add(chatPongWait))
	})
	outbound := handler.hub.Add(clientID, roomID)
	serverMessages := make(chan []byte, 4)
	writerDone := make(chan struct{})
	go writePump(connection, outbound, serverMessages, writerDone)
	defer func() {
		handler.hub.Remove(clientID, outbound)
		_ = connection.Close()
		<-writerDone
	}()

	for {
		messageType, message, readErr := connection.ReadMessage()
		if readErr != nil {
			return
		}
		if messageType != websocket.TextMessage || !validEvent(message) {
			if !queueMessage(serverMessages, writerDone, []byte(`{"error":"invalid event"}`)) {
				return
			}
			continue
		}
		eventMessage := message
		if eventMessage = enrichChatEvent(eventMessage, request.URL.Query().Get("roomId"), clientID); eventMessage == nil {
			if !queueMessage(serverMessages, writerDone, []byte(`{"error":"invalid chat event"}`)) {
				return
			}
			continue
		}
		if handler.sink != nil {
			if err := handler.sink.Handle(request.Context(), eventMessage); err != nil {
				if !queueMessage(serverMessages, writerDone, []byte(`{"error":"event rejected"}`)) {
					return
				}
				continue
			}
		}
		if isChatEvent(eventMessage) {
			handler.hub.Broadcast(roomID, eventMessage)
		}
	}
}

func writePump(connection *websocket.Conn, outbound <-chan []byte, serverMessages <-chan []byte, done chan<- struct{}) {
	defer close(done)
	defer connection.Close()

	ticker := time.NewTicker(chatPingEvery)
	defer ticker.Stop()

	for {
		select {
		case message, ok := <-outbound:
			if !ok {
				return
			}
			if err := connection.SetWriteDeadline(time.Now().Add(chatWriteWait)); err != nil {
				return
			}
			if err := connection.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case message := <-serverMessages:
			if err := connection.SetWriteDeadline(time.Now().Add(chatWriteWait)); err != nil {
				return
			}
			if err := connection.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			if err := connection.SetWriteDeadline(time.Now().Add(chatWriteWait)); err != nil {
				return
			}
			if err := connection.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func queueMessage(messages chan<- []byte, done <-chan struct{}, message []byte) bool {
	select {
	case <-done:
		return false
	default:
	}

	select {
	case messages <- message:
		return true
	case <-done:
		return false
	}
}

func isChatEvent(message []byte) bool {
	var event struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(message, &event) != nil {
		return false
	}
	return event.Type == "CHAT_MESSAGE" || event.Type == "message" || event.Type == "typing"
}

func validEvent(message []byte) bool {
	var event struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(message, &event) != nil {
		return false
	}
	switch event.Type {
	case "CHAT_MESSAGE", "message":
		return true
	case "typing":
		return validTypingEvent(message)
	default:
		return false
	}
}

func validTypingEvent(message []byte) bool {
	var event struct {
		IsTyping       *bool `json:"is_typing"`
		IsTypingLegacy *bool `json:"isTyping"`
	}
	if json.Unmarshal(message, &event) != nil {
		return false
	}
	return event.IsTyping != nil || event.IsTypingLegacy != nil
}

func enrichChatEvent(message []byte, roomID, clientID string) []byte {
	var event map[string]any
	if json.Unmarshal(message, &event) != nil {
		return nil
	}
	eventType, ok := event["type"].(string)
	if !ok {
		return nil
	}
	if eventType != "CHAT_MESSAGE" && eventType != "message" && eventType != "typing" {
		return message
	}
	if roomID == "" || clientID == "" {
		return nil
	}
	event["room_id"] = roomID
	event["sender_id"] = clientID
	if eventType == "typing" {
		isTyping, ok := event["is_typing"].(bool)
		if !ok {
			isTyping, ok = event["isTyping"].(bool)
		}
		if !ok {
			return nil
		}
		event["is_typing"] = isTyping
		delete(event, "isTyping")
	}
	return marshalEvent(event)
}

func marshalEvent(event map[string]any) []byte {
	message, err := json.Marshal(event)
	if err != nil {
		return nil
	}
	return message
}
