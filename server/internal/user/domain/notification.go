package domain

import "errors"

var ErrNotificationNotFound = errors.New("notification not found")

type Notification struct {
	ID        int
	UserID    int
	Type      string
	Title     string
	Body      string
	IsRead    bool
	CreatedAt string
}
