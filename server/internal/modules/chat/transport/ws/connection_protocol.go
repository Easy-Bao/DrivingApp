package ws

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/ws"
)

type EventSink interface {
	Handle(ctx context.Context, message []byte) error
}

type RoomAuthorizer interface {
	CanAccessRoom(ctx context.Context, roomID, userID string) (bool, error)
}

type ConnectionProtocol struct {
	sink    EventSink
	rooms   RoomAuthorizer
	limiter *ChatLimiter
}

type ConnectionProtocolOption func(*ConnectionProtocol)

func WithMessageRateLimit(limit int, window time.Duration) ConnectionProtocolOption {
	return func(p *ConnectionProtocol) {
		if limit > 0 && window > 0 {
			p.limiter.messageLimit = limit
			p.limiter.messageWindow = window
		}
	}
}

func WithTypingRateLimit(limit int, window, cooldown time.Duration) ConnectionProtocolOption {
	return func(p *ConnectionProtocol) {
		if limit > 0 && window > 0 {
			p.limiter.typingLimit = limit
			p.limiter.typingWindow = window
		}
		if cooldown > 0 {
			p.limiter.typingCooldown = cooldown
		}
	}
}

var _ websockethub.ConnectionProtocol = (*ConnectionProtocol)(nil)

func NewConnectionProtocol(sink EventSink, rooms RoomAuthorizer, opts ...ConnectionProtocolOption) *ConnectionProtocol {
	protocol := &ConnectionProtocol{
		sink:    sink,
		rooms:   rooms,
		limiter: newChatLimiter(),
	}
	for _, opt := range opts {
		opt(protocol)
	}
	return protocol
}

func (protocol *ConnectionProtocol) ResolveTopics(
	ctx context.Context,
	request *http.Request,
	identity security.Identity,
) ([]string, error) {
	roomID := request.URL.Query().Get("roomId")
	if roomID == "" {
		return nil, &websockethub.HandshakeError{
			StatusCode: http.StatusBadRequest,
			Message:    "Please select a valid chat room.",
			Cause:      errors.New("chat room id is required"),
		}
	}
	roomTopic, err := events.RoomTopic(roomID)
	if err != nil {
		return nil, &websockethub.HandshakeError{
			StatusCode: http.StatusBadRequest,
			Message:    "Please select a valid chat room.",
			Cause:      err,
		}
	}
	if protocol == nil || protocol.rooms == nil {
		return nil, &websockethub.HandshakeError{
			StatusCode: http.StatusServiceUnavailable,
			Message:    "Chat is temporarily unavailable. Please try again shortly.",
			Cause:      errors.New("chat room authorizer is unavailable"),
		}
	}
	allowed, err := protocol.rooms.CanAccessRoom(ctx, roomID, identity.Subject)
	if err != nil {
		return nil, &websockethub.HandshakeError{
			StatusCode: http.StatusServiceUnavailable,
			Message:    "Chat is temporarily unavailable. Please try again shortly.",
			Cause:      fmt.Errorf("authorize chat room: %w", err),
		}
	}
	if !allowed {
		return nil, &websockethub.HandshakeError{
			StatusCode: http.StatusForbidden,
			Message:    "You do not have permission to access this chat.",
			Cause:      errors.New("chat room access denied"),
		}
	}
	return []string{roomTopic}, nil
}

func (protocol *ConnectionProtocol) HandleMessage(
	ctx context.Context,
	request *http.Request,
	identity security.Identity,
	isText bool,
	message []byte,
) ([]byte, error) {
	parsed, eventType, isTyping, ok := parseClientChatEvent(message)
	if !isText || !ok {
		return formatWebSocketError("error", "invalid_event", "invalid event"), nil
	}
	roomID := request.URL.Query().Get("roomId")
	if roomID == "" || identity.Subject == "" {
		return formatWebSocketError("error", "invalid_chat_event", "invalid chat event"), nil
	}

	if eventType == "typing" {
		if protocol != nil && protocol.limiter != nil && !protocol.limiter.allowTyping(roomID, identity.Subject, isTyping) {
			return nil, nil
		}
		parsed["is_typing"] = isTyping
		delete(parsed, "isTyping")
	} else {
		if protocol != nil && protocol.limiter != nil && !protocol.limiter.allowMessage(roomID, identity.Subject) {
			return formatWebSocketError("error", "rate_limit_exceeded", "Too many messages. Please slow down."), nil
		}
	}

	parsed["room_id"] = roomID
	parsed["sender_id"] = identity.Subject
	enriched, err := json.Marshal(parsed)
	if err != nil {
		return formatWebSocketError("error", "invalid_chat_event", "invalid chat event"), nil
	}
	if protocol == nil || protocol.sink == nil {
		return formatWebSocketError("error", "event_rejected", "event rejected"), nil
	}
	if err := protocol.sink.Handle(ctx, enriched); err != nil {
		if errors.Is(err, domain.ErrRoomLocked) {
			return formatWebSocketError("room_locked", "room_locked", "Chat is closed for this trip."), nil
		}
		return formatWebSocketError("error", "event_rejected", "event rejected"), nil
	}
	return nil, nil
}

func formatWebSocketError(errorType, code, message string) []byte {
	payload, _ := json.Marshal(struct {
		Type    string `json:"type"`
		Code    string `json:"code"`
		Reason  string `json:"reason"`
		Message string `json:"message"`
	}{
		Type:    errorType,
		Code:    code,
		Reason:  message,
		Message: message,
	})
	return payload
}

func (protocol *ConnectionProtocol) EncodeEnvelope(envelope events.Envelope) ([]byte, error) {
	switch envelope.Type {
	case events.ChatMessageCreated:
		var payload struct {
			SenderID  string `json:"sender_id"`
			ImageKey  string `json:"image_key,omitempty"`
			Text      string `json:"text"`
			CreatedAt string `json:"created_at"`
		}
		if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
			return nil, fmt.Errorf("decode chat message event: %w", err)
		}
		if envelope.Scope.RoomID == "" || payload.SenderID == "" || (payload.Text == "" && payload.ImageKey == "") {
			return nil, errors.New("chat message event is incomplete")
		}
		return json.Marshal(struct {
			Type      string `json:"type"`
			ID        string `json:"id"`
			RoomID    string `json:"room_id"`
			SenderID  string `json:"sender_id"`
			ImageKey  string `json:"image_key,omitempty"`
			Text      string `json:"text"`
			CreatedAt string `json:"created_at"`
		}{
			Type:      "message",
			ID:        envelope.ID,
			RoomID:    envelope.Scope.RoomID,
			SenderID:  payload.SenderID,
			ImageKey:  payload.ImageKey,
			Text:      payload.Text,
			CreatedAt: payload.CreatedAt,
		})
	case events.ChatMessagesRead:
		var payload struct {
			SenderID    string `json:"sender_id"`
			ReadThrough string `json:"read_through"`
		}
		if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
			return nil, err
		}
		return json.Marshal(map[string]any{"type": "read", "sender_id": payload.SenderID, "read_through": payload.ReadThrough})
	case events.ChatTypingChanged:
		var payload struct {
			SenderID string `json:"sender_id"`
			IsTyping *bool  `json:"is_typing"`
		}
		if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
			return nil, fmt.Errorf("decode chat typing event: %w", err)
		}
		if envelope.Scope.RoomID == "" || payload.SenderID == "" || payload.IsTyping == nil {
			return nil, errors.New("chat typing event is incomplete")
		}
		return json.Marshal(struct {
			Type     string `json:"type"`
			RoomID   string `json:"room_id"`
			SenderID string `json:"sender_id"`
			IsTyping bool   `json:"is_typing"`
		}{
			Type:     "typing",
			RoomID:   envelope.Scope.RoomID,
			SenderID: payload.SenderID,
			IsTyping: *payload.IsTyping,
		})
	default:
		return nil, nil
	}
}

func parseClientChatEvent(message []byte) (map[string]any, string, bool, bool) {
	var parsed map[string]any
	if json.Unmarshal(message, &parsed) != nil || parsed == nil {
		return nil, "", false, false
	}
	eventType, ok := parsed["type"].(string)
	if !ok {
		return nil, "", false, false
	}
	switch eventType {
	case "CHAT_MESSAGE", "message":
		return parsed, eventType, false, true
	case "typing":
		isTyping, ok := extractTypingFlag(parsed)
		if !ok {
			return nil, "", false, false
		}
		return parsed, eventType, isTyping, true
	default:
		return nil, "", false, false
	}
}

func extractTypingFlag(parsed map[string]any) (bool, bool) {
	if raw, exists := parsed["is_typing"]; exists && raw != nil {
		isTyping, ok := raw.(bool)
		return isTyping, ok
	}
	if raw, exists := parsed["isTyping"]; exists && raw != nil {
		isTyping, ok := raw.(bool)
		return isTyping, ok
	}
	return false, false
}
