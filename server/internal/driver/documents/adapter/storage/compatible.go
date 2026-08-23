package storage

import (
	"context"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/domain"
)

type LegacyReader interface {
	Read(ctx context.Context, key string, maxBytes int64) ([]byte, error)
}

type CompatibleStorage struct {
	primary domain.ObjectStorage
	legacy  LegacyReader
}

func NewCompatibleStorage(primary domain.ObjectStorage, legacy LegacyReader) *CompatibleStorage {
	return &CompatibleStorage{primary: primary, legacy: legacy}
}

func (storage *CompatibleStorage) Store(ctx context.Context, content []byte) (string, error) {
	return storage.primary.Store(ctx, content)
}

func (storage *CompatibleStorage) Read(ctx context.Context, key string, maxBytes int64) ([]byte, error) {
	if strings.HasPrefix(key, "driver:document:") && storage.legacy != nil {
		return storage.legacy.Read(ctx, key, maxBytes)
	}
	return storage.primary.Read(ctx, key, maxBytes)
}

func (storage *CompatibleStorage) Delete(ctx context.Context, key string) error {
	return storage.primary.Delete(ctx, key)
}
