package stream

import (
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	"github.com/gorilla/websocket"
)

const (
	maximumMessageSize = 8 << 10
	pongWait           = 60 * time.Second
	pingPeriod         = 54 * time.Second
	writeWait          = 10 * time.Second
)

type IdentityAuthenticator interface {
	VerifyIdentity(token string) (security.Identity, error)
}

type Handler struct {
	hub            *Hub
	authenticator  IdentityAuthenticator
	allowedOrigins map[string]struct{}
	upgrader       websocket.Upgrader
}

func NewHandler(hub *Hub, authenticator IdentityAuthenticator, allowedOrigins []string) *Handler {
	origins := make(map[string]struct{}, len(allowedOrigins))
	for _, origin := range allowedOrigins {
		if trimmed := strings.TrimSpace(origin); trimmed != "" {
			origins[trimmed] = struct{}{}
		}
	}
	handler := &Handler{hub: hub, authenticator: authenticator, allowedOrigins: origins}
	handler.upgrader = websocket.Upgrader{CheckOrigin: handler.originAllowed}
	return handler
}

func (handler *Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if handler == nil || handler.hub == nil || handler.authenticator == nil {
		response.Error(writer, http.StatusServiceUnavailable, "Live updates are temporarily unavailable. Please try again shortly.")
		return
	}
	identity, ok := handler.identity(request)
	if !ok {
		response.Error(writer, http.StatusUnauthorized, "Your session has expired. Please sign in again to continue.")
		return
	}
	topics, err := topicsForIdentity(identity)
	if err != nil {
		response.Error(writer, http.StatusForbidden, "You do not have permission to receive these live updates.")
		return
	}

	subscription := handler.hub.Subscribe(topics...)
	defer subscription.Close()
	connection, err := handler.upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return
	}

	stopWriter := make(chan struct{})
	writerDone := make(chan struct{})
	go handler.writePump(connection, subscription.Events(), stopWriter, writerDone)
	handler.readPump(connection)
	close(stopWriter)
	_ = connection.Close()
	<-writerDone
}

func (handler *Handler) identity(request *http.Request) (security.Identity, bool) {
	token, ok := middleware.BearerToken(request.Header.Get("Authorization"))
	if !ok {
		return security.Identity{}, false
	}
	identity, err := handler.authenticator.VerifyIdentity(token)
	return identity, err == nil && identity.Subject != ""
}

func (handler *Handler) originAllowed(request *http.Request) bool {
	origin := strings.TrimSpace(request.Header.Get("Origin"))
	if origin == "" {
		return true
	}
	_, allowed := handler.allowedOrigins[origin]
	return allowed
}

func (handler *Handler) readPump(connection *websocket.Conn) {
	connection.SetReadLimit(maximumMessageSize)
	if err := connection.SetReadDeadline(time.Now().Add(pongWait)); err != nil {
		return
	}
	connection.SetPongHandler(func(string) error {
		return connection.SetReadDeadline(time.Now().Add(pongWait))
	})
	for {
		if _, _, err := connection.ReadMessage(); err != nil {
			return
		}
	}
}

func (handler *Handler) writePump(connection *websocket.Conn, events <-chan event.Envelope, stop <-chan struct{}, done chan<- struct{}) {
	defer close(done)
	defer connection.Close()

	ticker := time.NewTicker(pingPeriod)
	defer ticker.Stop()
	for {
		select {
		case <-stop:
			return
		case envelope, ok := <-events:
			if !ok {
				return
			}
			if err := connection.SetWriteDeadline(time.Now().Add(writeWait)); err != nil {
				return
			}
			if err := connection.WriteJSON(envelope); err != nil {
				return
			}
		case <-ticker.C:
			if err := connection.SetWriteDeadline(time.Now().Add(writeWait)); err != nil {
				return
			}
			if err := connection.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func topicsForIdentity(identity security.Identity) ([]string, error) {
	switch identity.Role {
	case "driver":
		topic, err := event.DriverTopic(identity.Subject)
		if err != nil {
			return nil, err
		}
		return []string{topic, event.DriverPoolTopic}, nil
	case "passenger":
		topic, err := event.PassengerTopic(identity.Subject)
		return []string{topic}, err
	default:
		return nil, errors.New("unsupported realtime role")
	}
}
