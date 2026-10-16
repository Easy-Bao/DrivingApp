package app

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/driver/domain"
)

// DocumentStore isolates document workflow state from the database adapter.
type DocumentStore interface {
	Create(ctx context.Context, document domain.Document) (domain.Document, error)
	Get(ctx context.Context, id int) (domain.Document, error)
	ListByDriver(ctx context.Context, driverID, limit int) ([]domain.Document, error)
	ListForReview(ctx context.Context, status domain.Status, limit, offset int) ([]domain.Document, error)
	Review(ctx context.Context, id, reviewerID int, status domain.Status) (domain.Document, error)
}

// ObjectStore is the document module's outbound port for bounded private
// binary storage. The domain does not depend on the platform adapter.
type ObjectStore interface {
	Store(ctx context.Context, content []byte) (string, error)
	Read(ctx context.Context, key string, maxBytes int64) ([]byte, error)
	Delete(ctx context.Context, key string) error
}
