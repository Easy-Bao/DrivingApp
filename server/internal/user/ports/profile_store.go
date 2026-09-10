package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

// ProfileStore isolates profile aggregate persistence from application use cases.
type ProfileStore interface {
	Get(ctx context.Context, userID int) (domain.Profile, error)
	Save(ctx context.Context, profile domain.Profile) (domain.Profile, error)
}
