package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

// AvatarStore keeps private avatar bytes behind the user boundary.
type AvatarStore interface {
	SaveAvatar(ctx context.Context, userID int, content []byte, contentType string) (domain.Profile, error)
	GetAvatar(ctx context.Context, userID int) (domain.Avatar, error)
}
