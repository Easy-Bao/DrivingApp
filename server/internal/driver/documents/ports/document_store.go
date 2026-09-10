package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

// DocumentStore isolates document workflow state from the database adapter.
type DocumentStore interface {
	Create(ctx context.Context, document domain.Document) (domain.Document, error)
	Get(ctx context.Context, id int) (domain.Document, error)
	ListByDriver(ctx context.Context, driverID, limit int) ([]domain.Document, error)
	ListForReview(ctx context.Context, status domain.Status, limit, offset int) ([]domain.Document, error)
	Review(ctx context.Context, id, reviewerID int, status domain.Status) (domain.Document, error)
}
