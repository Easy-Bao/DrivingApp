package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/user/domain"

type NotificationResponse struct {
	ID        int    `json:"id"`
	UserID    int    `json:"user_id"`
	Type      string `json:"type"`
	Title     string `json:"title"`
	Body      string `json:"body"`
	IsRead    bool   `json:"is_read"`
	CreatedAt string `json:"created_at"`
}

func NewNotificationResponses(notifications []domain.Notification) []NotificationResponse {
	if notifications == nil {
		return []NotificationResponse{}
	}

	responses := make([]NotificationResponse, 0, len(notifications))
	for _, notification := range notifications {
		responses = append(responses, NotificationResponse{
			ID:        notification.ID,
			UserID:    notification.UserID,
			Type:      notification.Type,
			Title:     notification.Title,
			Body:      notification.Body,
			IsRead:    notification.IsRead,
			CreatedAt: notification.CreatedAt,
		})
	}
	return responses
}
