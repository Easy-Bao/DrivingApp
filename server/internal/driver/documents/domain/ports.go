package domain

import "context"

type Repository interface {
	Create(ctx context.Context, document Document) (Document, error)
	Get(ctx context.Context, id int) (Document, error)
	ListByDriver(ctx context.Context, driverID, limit int) ([]Document, error)
	ListForReview(ctx context.Context, status Status, limit, offset int) ([]Document, error)
	Review(ctx context.Context, id, reviewerID int, status Status) (Document, error)
}

type ObjectStorage interface {
	Store(ctx context.Context, content []byte) (string, error)
	Read(ctx context.Context, key string, maxBytes int64) ([]byte, error)
	Delete(ctx context.Context, key string) error
}
