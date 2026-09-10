package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

// ProfileStore persists the profile aggregate used by profile use cases.
type ProfileStore interface {
	Get(ctx context.Context, userID int) (domain.Profile, error)
	Save(ctx context.Context, profile domain.Profile) (domain.Profile, error)
}
