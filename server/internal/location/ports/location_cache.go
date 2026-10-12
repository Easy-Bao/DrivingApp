package ports

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
)

var ErrCacheMiss = errors.New("location cache miss")

// Cache stores bounded provider responses without coupling location use cases
// to a cache implementation.
type Cache interface {
	GetPlaces(ctx context.Context, key string) ([]domain.Place, error)
	SetPlaces(ctx context.Context, key string, places []domain.Place) error
	GetPlace(ctx context.Context, key string) (*domain.Place, error)
	SetPlace(ctx context.Context, key string, place *domain.Place) error
	GetMatrix(ctx context.Context, key string) (*domain.Matrix, error)
	SetMatrix(ctx context.Context, key string, matrix *domain.Matrix) error
}
