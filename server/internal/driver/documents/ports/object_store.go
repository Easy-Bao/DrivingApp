package ports

import "context"

// ObjectStore is the document module's outbound port for bounded private
// binary storage. The domain does not depend on the platform adapter.
type ObjectStore interface {
	Store(ctx context.Context, content []byte) (string, error)
	Read(ctx context.Context, key string, maxBytes int64) ([]byte, error)
	Delete(ctx context.Context, key string) error
}
