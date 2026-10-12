package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/chat/domain"

type MessageResponse struct {
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
		Text:            message.Body,
		Message:         message.Body,
		SenderID:        message.SenderID,
		LegacySenderID:  message.SenderID,
		CreatedAt:       message.CreatedAt,
		LegacyCreatedAt: message.CreatedAt,
	}
}
