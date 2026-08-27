package domain

import (
	"context"

	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
)

type Repository interface {
	Create(ctx context.Context, document Document) (Document, error)
	Get(ctx context.Context, id int) (Document, error)
	ListByDriver(ctx context.Context, driverID, limit int) ([]Document, error)
	ListForReview(ctx context.Context, status Status, limit, offset int) ([]Document, error)
	Review(ctx context.Context, id, reviewerID int, status Status) (Document, error)
}

type ObjectStorage = platformstorage.ObjectStore
