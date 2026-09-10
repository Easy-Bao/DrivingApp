package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

// AvatarStore persists and reads private passenger avatar objects.
type AvatarStore interface {
	SaveAvatar(ctx context.Context, userID int, content []byte, contentType string) (domain.Profile, error)
	GetAvatar(ctx context.Context, userID int) (domain.Avatar, error)
}
