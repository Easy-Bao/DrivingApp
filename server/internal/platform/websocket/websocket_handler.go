package hub

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/gorilla/websocket"
)

const (
	_maximumMessageSize = 8 << 10
	_pongWait           = 60 * time.Second
	_pingPeriod         = 54 * time.Second
	_writeWait          = 10 * time.Second
)

type IdentityAuthenticator interface {
	VerifyIdentity(token string) (security.Identity, error)
}

type Handler struct {
	hub            *Hub
	authenticator  IdentityAuthenticator
	logger         *slog.Logger
	allowedOrigins map[string]struct{}
	upgrader       websocket.Upgrader
}

var _ http.Handler = (*Handler)(nil)

type HandlerOption func(*Handler)

type HandlerDependencies struct {
	Hub           *Hub
	Authenticator IdentityAuthenticator
}

func WithLogger(logger *slog.Logger) HandlerOption {
	return func(handler *Handler) {
		if logger != nil {
			handler.logger = logger
		}
	}
}

func WithAllowedOrigins(origins []string) HandlerOption {
	return func(handler *Handler) {
		for _, origin := range origins {
			if trimmed := strings.TrimSpace(origin); trimmed != "" {
				handler.allowedOrigins[trimmed] = struct{}{}
			}
		}
	}
}

func NewHandler(dependencies HandlerDependencies, options ...HandlerOption) *Handler {
	handler := &Handler{
		hub:            dependencies.Hub,
		authenticator:  dependencies.Authenticator,
		logger:         slog.Default(),
		allowedOrigins: make(map[string]struct{}),
	}
	for _, option := range options {
		if option != nil {
			option(handler)
		}
	}
	handler.upgrader = websocket.Upgrader{CheckOrigin: handler.originAllowed}
	return handler
}

func (handler *Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	missingHandler := handler == nil
	missingHub := handler != nil && handler.hub == nil
	missingAuthenticator := handler != nil && handler.authenticator == nil
	if missingHandler || missingHub || missingAuthenticator {
		response.Error(
			writer,
			http.StatusServiceUnavailable,
			"Live updates are temporarily unavailable. Please try again shortly.",
		)
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
	var closeOnce sync.Once
	debugMetricsEnabled := handler.logger.Enabled(request.Context(), slog.LevelDebug)
	var startedAt time.Time
	var stats *connectionWriteStats
	if debugMetricsEnabled {
		startedAt = time.Now()
		stats = &connectionWriteStats{}
	}
	closeConnection := func() {
		closeOnce.Do(func() {
			if err := connection.Close(); err != nil {
				slog.DebugContext(request.Context(), "close realtime websocket failed", "error", err)
			}
		})
	}

	stopWriter := make(chan struct{})
	writerDone := make(chan struct{})
	go handler.writePump(
		connection,
		subscription.Events(),
		stopWriter,
		writerDone,
		closeConnection,
		stats,
	)
	readDone := make(chan struct{})
	go func() {
		handler.readPump(connection)
		close(readDone)
	}()
	select {
	case <-readDone:
	case <-writerDone:
		// A failed write is the first signal for a half-open socket. Stop
		// waiting on the reader so the subscription is scavenged immediately.
	}
	close(stopWriter)
	closeConnection()
	<-readDone
	<-writerDone
	if debugMetricsEnabled {
		handler.logger.DebugContext(
			request.Context(),
			"realtime websocket closed",
			"request_id", middleware.RequestIDFromRequest(request),
			"role", identity.Role,
			"connection_duration_ms", time.Since(startedAt).Milliseconds(),
			"events_sent", stats.eventsSent,
			"pings_sent", stats.pingsSent,
		)
	}
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
	connection.SetReadLimit(_maximumMessageSize)
	if err := connection.SetReadDeadline(time.Now().Add(_pongWait)); err != nil {
		return
	}
	connection.SetPongHandler(func(string) error {
		return connection.SetReadDeadline(time.Now().Add(_pongWait))
	})
	for {
		if _, _, err := connection.ReadMessage(); err != nil {
			return
		}
	}
}

func (handler *Handler) writePump(
	connection *websocket.Conn,
	events <-chan event.Envelope,
	stop <-chan struct{},
	done chan<- struct{},
	closeConnection func(),
	stats *connectionWriteStats,
) {
	defer close(done)
	defer closeConnection()

	ticker := time.NewTicker(_pingPeriod)
	defer ticker.Stop()
	for {
		select {
		case <-stop:
			return
		case envelope, ok := <-events:
			if !ok {
				return
			}
			if err := connection.SetWriteDeadline(time.Now().Add(_writeWait)); err != nil {
				return
			}
			if err := connection.WriteJSON(envelope); err != nil {
				return
			}
			if stats != nil {
				stats.eventsSent++
			}
		case <-ticker.C:
			if err := connection.SetWriteDeadline(time.Now().Add(_writeWait)); err != nil {
				return
			}
			if err := connection.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
			if stats != nil {
				stats.pingsSent++
			}
		}
	}
}

// writePump owns these counters; ServeHTTP reads them after writerDone closes.
type connectionWriteStats struct {
	eventsSent int
	pingsSent  int
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
