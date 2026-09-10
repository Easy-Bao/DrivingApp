package domain

import "context"

type Repository interface {
	Stats(ctx context.Context) (Stats, error)
}
