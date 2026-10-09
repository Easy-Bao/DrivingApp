package ws

import (
	"log/slog"
	"sync"
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
