package domain

import "context"

type Repository interface {
	Create(ctx context.Context, document Document) (Document, error)
	List(ctx context.Context, driverID int) ([]Document, error)
	Review(ctx context.Context, id int, status Status) (Document, error)
}
type Storage interface {
	Put(ctx context.Context, driverID int, documentType string, content []byte) (string, error)
}
