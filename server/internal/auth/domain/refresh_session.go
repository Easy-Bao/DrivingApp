package domain

import "time"

type RefreshSession struct {
	UserID    int
	TokenHash string
	ExpiresAt time.Time
}
