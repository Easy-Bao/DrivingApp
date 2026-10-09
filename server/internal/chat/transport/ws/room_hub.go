package ws

import (
	"encoding/json"
	"log/slog"
	"sync"

	events "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

const _roomOutboundQueueSize = 64

type RoomHub struct {
	mu      sync.RWMutex
	clients map[string]client
}

type client struct {
	roomID  string
	channel chan []byte
}

func NewRoomHub() *RoomHub {
	return &RoomHub{clients: make(map[string]client)}
}

// Publish forwards persisted chat messages to local room connections. The
// event envelope keeps the Redis transport independent of the WebSocket wire
// format used by chat clients.
func (hub *RoomHub) Publish(envelope events.Envelope) {
	if hub == nil || envelope.Type != events.ChatMessageCreated {
		return
	}

	var payload struct {
		SenderID  string `json:"sender_id"`
		Text      string `json:"text"`
		CreatedAt string `json:"created_at"`
	}
	if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
		slog.Warn("ignore invalid chat message event", "error", err)
		return
	}
	if envelope.Scope.RoomID == "" || payload.SenderID == "" || payload.Text == "" {
		slog.Warn("ignore incomplete chat message event")
		return
	}

	message, err := json.Marshal(struct {
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
	if err != nil {
		slog.Warn("encode chat websocket message failed", "error", err)
		return
	}
	hub.Broadcast(envelope.Scope.RoomID, message)
}

func (hub *RoomHub) Add(id, roomID string) chan []byte {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	channel := make(chan []byte, _roomOutboundQueueSize)
	if existing, ok := hub.clients[id]; ok {
		close(existing.channel)
	}
	hub.clients[id] = client{roomID: roomID, channel: channel}
	return channel
}

func (hub *RoomHub) Remove(id string, channels ...chan []byte) {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	if existing, ok := hub.clients[id]; ok {
		if len(channels) > 0 && existing.channel != channels[0] {
			return
		}
		delete(hub.clients, id)
		close(existing.channel)
	}
}

func (hub *RoomHub) Broadcast(roomID string, message []byte) {
	hub.mu.RLock()
	type slowClient struct {
		id      string
		channel chan []byte
	}
	var slowClients []slowClient
	for id, existing := range hub.clients {
		if existing.roomID != roomID {
			continue
		}
		select {
		case existing.channel <- message:
		default:
			slowClients = append(slowClients, slowClient{id: id, channel: existing.channel})
		}
	}
	hub.mu.RUnlock()

	for _, client := range slowClients {
		slog.Warn(
			"closing chat websocket client with a full outbound queue",
			"queue_capacity", cap(client.channel),
		)
		hub.Remove(client.id, client.channel)
	}
}
