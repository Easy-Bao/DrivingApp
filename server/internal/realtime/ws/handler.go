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
	upgrader     websocket.Upgrader
}

type Authenticator interface {
	Verify(token string) (string, error)
}

func NewHandler(hub *Hub, authenticate Authenticator) *Handler {
	return &Handler{
		hub:          hub,
		authenticate: authenticate,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(*http.Request) bool { return false },
		},
	}
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
		handler.hub.Broadcast(message)
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
	case "LOCATION_UPDATE", "CHAT_MESSAGE", "BID_CREATED":
		return true
	default:
		return false
	}
}
