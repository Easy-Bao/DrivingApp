package storage

import "context"

// ObjectStore persists private binary objects and returns an opaque key that
// feature metadata can reference. Implementations must keep object reads
// bounded by maxBytes and reject keys they did not issue.
type ObjectStore interface {
	Store(ctx context.Context, content []byte) (string, error)
	Read(ctx context.Context, key string, maxBytes int64) ([]byte, error)
	Delete(ctx context.Context, key string) error
}
