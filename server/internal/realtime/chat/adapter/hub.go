package adapter

import (
	"sync"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
)

type Hub struct {
	mu          sync.RWMutex
	subscribers map[string][]chan domain.Message
}

func NewHub() *Hub { return &Hub{subscribers: map[string][]chan domain.Message{}} }
func (hub *Hub) Subscribe(roomID string) <-chan domain.Message {
	channel := make(chan domain.Message, 16)
	hub.mu.Lock()
	hub.subscribers[roomID] = append(hub.subscribers[roomID], channel)
	hub.mu.Unlock()
	return channel
}
func (hub *Hub) Publish(message domain.Message) error {
	hub.mu.RLock()
	defer hub.mu.RUnlock()
	for _, channel := range hub.subscribers[message.RoomID] {
		select {
		case channel <- message:
		default:
		}
	}
	return nil
}
