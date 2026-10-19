package http

import "github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"

type ProfileResponse struct {
	ID                int     `json:"id"`
	UserID            int     `json:"user_id"`
	Role              string  `json:"role"`
	Name              string  `json:"name"`
	Phone             string  `json:"phone,omitempty"`
	Email             string  `json:"email,omitempty"`
	Address           string  `json:"address,omitempty"`
	Gender            string  `json:"gender,omitempty"`
	AvatarURL         string  `json:"avatar_url,omitempty"`
	PreferredRideType string  `json:"preferred_ride_type,omitempty"`
	VehicleType       string  `json:"vehicle_type,omitempty"`
	PlateNumber       string  `json:"plate_number,omitempty"`
	Rating            float64 `json:"rating,omitempty"`
	IsOnline          bool    `json:"is_online,omitempty"`
}

func NewProfileResponse(profile domain.Profile) ProfileResponse {
	return ProfileResponse{
		ID:                profile.ID,
		UserID:            profile.UserID,
		Role:              profile.Role,
		Name:              profile.Name,
		Phone:             profile.Phone,
		Email:             profile.Email,
		Address:           profile.Address,
		Gender:            profile.Gender,
		AvatarURL:         profile.AvatarURL,
		PreferredRideType: profile.PreferredRideType,
		VehicleType:       profile.VehicleType,
		PlateNumber:       profile.PlateNumber,
		Rating:            profile.Rating,
		IsOnline:          profile.IsOnline,
	}
}

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
