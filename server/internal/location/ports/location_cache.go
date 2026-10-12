package ports

import (
	"context"
	"errors"
)

var ErrCacheMiss = errors.New("location cache miss")

// Cache stores bounded provider responses without coupling location use cases
// to a cache implementation.
type Cache interface {
	Get(ctx context.Context, key string, target any) error
	Set(ctx context.Context, key string, value any) error
}
