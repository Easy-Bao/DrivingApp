package app

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

// ProfileStore isolates profile aggregate persistence from application use cases.
type ProfileStore interface {
	Get(ctx context.Context, userID int) (domain.Profile, error)
	Save(ctx context.Context, profile domain.Profile) (domain.Profile, error)
	UpdateOnlineStatus(
		ctx context.Context,
		userID int,
		targetID int,
		isOnline bool,
	) (domain.Profile, error)
}

// AvatarStore keeps private avatar bytes behind the user boundary.
type AvatarStore interface {
	SaveAvatar(ctx context.Context, userID int, content []byte, contentType string) (domain.Profile, error)
	GetAvatar(ctx context.Context, userID int) (domain.Avatar, error)
}

// NotificationStore provides the bounded notification read and delete boundary.
type NotificationStore interface {
	Notifications(ctx context.Context, userID, limit, offset int) ([]domain.Notification, error)
	DeleteNotification(ctx context.Context, userID, notificationID int) error
}
