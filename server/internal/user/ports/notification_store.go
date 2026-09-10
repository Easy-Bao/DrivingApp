package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

// NotificationStore reads and deletes a user's notifications.
type NotificationStore interface {
	Notifications(ctx context.Context, userID, limit, offset int) ([]domain.Notification, error)
	DeleteNotification(ctx context.Context, userID, notificationID int) error
}
