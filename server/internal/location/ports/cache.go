package ports

import (
	"context"
)

// Cache stores bounded location-provider responses.
type Cache interface {
	Get(ctx context.Context, key string, target any) error
	Set(ctx context.Context, key string, value any) error
}
