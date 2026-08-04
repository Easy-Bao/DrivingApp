package ws

import "sync"

type Hub struct {
	mu      sync.RWMutex
	clients map[string]chan []byte
}

func NewHub() *Hub {
	return &Hub{clients: make(map[string]chan []byte)}
}

func (hub *Hub) Add(id string) chan []byte {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	channel := make(chan []byte, 16)
	hub.clients[id] = channel
	return channel
}

func (hub *Hub) Remove(id string) {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	if channel, ok := hub.clients[id]; ok {
		delete(hub.clients, id)
		close(channel)
	}
}

func (hub *Hub) Broadcast(message []byte) {
	hub.mu.RLock()
	defer hub.mu.RUnlock()
	for _, channel := range hub.clients {
		select {
		case channel <- message:
		default:
		}
	}
}
