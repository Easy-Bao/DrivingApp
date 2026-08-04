package ws

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/gorilla/websocket"
)

type Handler struct {
	hub          *Hub
	authenticate Authenticator
	sink         EventSink
	upgrader     websocket.Upgrader
}

type Authenticator interface {
	Verify(token string) (string, error)
}

type EventSink interface{ Handle(message []byte) error }

func NewHandler(hub *Hub, authenticate Authenticator) *Handler {
	return &Handler{
		hub:          hub,
		authenticate: authenticate,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(*http.Request) bool { return false },
		},
	}
}

func NewHandlerWithSink(hub *Hub, authenticate Authenticator, sink EventSink) *Handler {
	handler := NewHandler(hub, authenticate)
	handler.sink = sink
	return handler
}

func (handler *Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	connection, err := handler.upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return
	}
	defer connection.Close()

	token := strings.TrimPrefix(request.Header.Get("Authorization"), "Bearer ")
	clientID, err := handler.authenticate.Verify(token)
	if err != nil {
		_ = connection.WriteJSON(map[string]string{"error": "unauthorized"})
		return
	}
	outbound := handler.hub.Add(clientID)
	defer handler.hub.Remove(clientID)

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
			_ = handler.sink.Handle(eventMessage)
		}
		handler.hub.Broadcast(eventMessage)
	}
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
