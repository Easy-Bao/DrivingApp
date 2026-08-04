package domain

type Message struct {
	RoomID   string `json:"room_id"`
	SenderID string `json:"sender_id"`
	Body     string `json:"body"`
}
type Publisher interface{ Publish(message Message) error }
