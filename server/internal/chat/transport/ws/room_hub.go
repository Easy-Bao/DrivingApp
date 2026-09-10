package ws

import "sync"

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
	channel := make(chan []byte, 16)
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
