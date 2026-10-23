package http

import "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"

type MessageResponse struct {
	ID              string `json:"id"`
	ImageKey        string `json:"image_key,omitempty"`
	Seen            bool   `json:"seen"`
	Text            string `json:"text"`
	Message         string `json:"message"`
	SenderID        string `json:"sender_id"`
	LegacySenderID  string `json:"senderId"`
	CreatedAt       string `json:"created_at"`
	LegacyCreatedAt string `json:"createdAt"`
}

func NewMessageResponses(messages []domain.Message) []MessageResponse {
	if messages == nil {
		return []MessageResponse{}
	}

	responses := make([]MessageResponse, 0, len(messages))
	for _, message := range messages {
		responses = append(responses, NewMessageResponse(message))
	}
	return responses
}

func NewMessageResponse(message domain.Message) MessageResponse {
	return MessageResponse{
		ID: message.ID, ImageKey: message.ImageKey, Seen: message.Seen,
		Text:            message.Body,
		Message:         message.Body,
		SenderID:        message.SenderID,
		LegacySenderID:  message.SenderID,
		CreatedAt:       message.CreatedAt,
		LegacyCreatedAt: message.CreatedAt,
	}
}
