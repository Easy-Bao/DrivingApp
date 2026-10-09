package ws

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/websocket"
)

type EventSink interface {
	Handle(ctx context.Context, message []byte) error
}

type RoomAuthorizer interface {
	CanAccessRoom(ctx context.Context, roomID, userID string) (bool, error)
}

type ConnectionProtocol struct {
	sink  EventSink
	rooms RoomAuthorizer
}

var _ websockethub.ConnectionProtocol = (*ConnectionProtocol)(nil)

func NewConnectionProtocol(sink EventSink, rooms RoomAuthorizer) *ConnectionProtocol {
	return &ConnectionProtocol{sink: sink, rooms: rooms}
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
		return []byte(`{"error":"invalid event"}`), nil
	}
	roomID := request.URL.Query().Get("roomId")
	enriched := enrichChatEvent(message, roomID, identity.Subject)
	if enriched == nil {
		return []byte(`{"error":"invalid chat event"}`), nil
	}
	if protocol == nil || protocol.sink == nil {
		return []byte(`{"error":"event rejected"}`), nil
	}
	if err := protocol.sink.Handle(ctx, enriched); err != nil {
		return []byte(`{"error":"event rejected"}`), nil
	}
	return nil, nil
}

func (protocol *ConnectionProtocol) EncodeEnvelope(envelope events.Envelope) ([]byte, error) {
	switch envelope.Type {
	case events.ChatMessageCreated:
		var payload struct {
			SenderID  string `json:"sender_id"`
			Text      string `json:"text"`
			CreatedAt string `json:"created_at"`
		}
		if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
			return nil, fmt.Errorf("decode chat message event: %w", err)
		}
		if envelope.Scope.RoomID == "" || payload.SenderID == "" || payload.Text == "" {
			return nil, errors.New("chat message event is incomplete")
		}
		return json.Marshal(struct {
			Type      string `json:"type"`
			ID        string `json:"id"`
			RoomID    string `json:"room_id"`
			SenderID  string `json:"sender_id"`
			Text      string `json:"text"`
			CreatedAt string `json:"created_at"`
		}{
			Type:      "message",
			ID:        envelope.ID,
			RoomID:    envelope.Scope.RoomID,
			SenderID:  payload.SenderID,
			Text:      payload.Text,
			CreatedAt: payload.CreatedAt,
		})
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
