package domain

import "context"

type Repository interface {
	Get(ctx context.Context, userID int) (Profile, error)
	Save(ctx context.Context, profile Profile) (Profile, error)
}

type NotificationRepository interface {
	Notifications(ctx context.Context, userID int) ([]Notification, error)
}
