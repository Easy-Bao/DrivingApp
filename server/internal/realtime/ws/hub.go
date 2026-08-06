package ws

import "sync"

type Hub struct {
	mu      sync.RWMutex
	clients map[string]client
}

type client struct {
	roomID  string
	channel chan []byte
}

func NewHub() *Hub {
	return &Hub{clients: make(map[string]client)}
}

func (hub *Hub) Add(id, roomID string) chan []byte {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	channel := make(chan []byte, 16)
	if existing, ok := hub.clients[id]; ok {
		close(existing.channel)
	}
	hub.clients[id] = client{roomID: roomID, channel: channel}
	return channel
}

func (hub *Hub) Remove(id string, channels ...chan []byte) {
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

func (hub *Hub) Broadcast(roomID string, message []byte) {
	hub.mu.RLock()
	defer hub.mu.RUnlock()
	for _, existing := range hub.clients {
		if existing.roomID != roomID {
			continue
		}
		select {
		case existing.channel <- message:
		default:
		}
	}
}
