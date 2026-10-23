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

func withLimiterClock(now func() time.Time) ConnectionProtocolOption {
	return func(p *ConnectionProtocol) {
		p.limiter.now = now
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
	if !isText || !validEvent(message) {
		return formatWebSocketError("error", "invalid_event", "invalid event"), nil
	}
	roomID := request.URL.Query().Get("roomId")
	if roomID == "" || identity.Subject == "" {
		return formatWebSocketError("error", "invalid_chat_event", "invalid chat event"), nil
	}

	var eventHeader struct {
		Type           string `json:"type"`
		IsTyping       *bool  `json:"is_typing"`
		IsTypingLegacy *bool  `json:"isTyping"`
	}
	_ = json.Unmarshal(message, &eventHeader)

	if eventHeader.Type == "typing" {
		isTyping := false
		if eventHeader.IsTyping != nil {
			isTyping = *eventHeader.IsTyping
		} else if eventHeader.IsTypingLegacy != nil {
			isTyping = *eventHeader.IsTypingLegacy
		}
		if protocol != nil && protocol.limiter != nil {
			if !protocol.limiter.allowTyping(roomID, identity.Subject, isTyping) {
				return nil, nil
			}
		}
	} else if eventHeader.Type == "CHAT_MESSAGE" || eventHeader.Type == "message" {
		if protocol != nil && protocol.limiter != nil {
			if !protocol.limiter.allowMessage(roomID, identity.Subject) {
				return formatWebSocketError("error", "rate_limit_exceeded", "Too many messages. Please slow down."), nil
			}
		}
	}

	enriched := enrichChatEvent(message, roomID, identity.Subject)
	if enriched == nil {
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
	isChatMessage := eventType == "CHAT_MESSAGE" || eventType == "message"
	isTypingEvent := eventType == "typing"
	if !isChatMessage && !isTypingEvent {
		return nil
	}
	if roomID == "" || clientID == "" {
		return nil
	}
	event["room_id"] = roomID
	event["sender_id"] = clientID
	if isTypingEvent {
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
	enriched, err := json.Marshal(event)
	if err != nil {
		return nil
	}
	return enriched
}
