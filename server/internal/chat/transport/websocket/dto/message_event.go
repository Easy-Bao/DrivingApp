package dto

type MessageEvent struct {
	RoomID   string `json:"room_id"`
	SenderID string `json:"sender_id"`
	Body     string `json:"body"`
	Text     string `json:"text"`
}
