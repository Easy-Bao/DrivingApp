package storage

import (
	"context"
	"fmt"

	redisclient "github.com/redis/go-redis/v9"
)

type RedisStorage struct{ client *redisclient.Client }

func NewRedisStorage(client *redisclient.Client) *RedisStorage { return &RedisStorage{client: client} }

func (storage *RedisStorage) Put(ctx context.Context, driverID int, documentType string, content []byte) (string, error) {
	key := fmt.Sprintf("driver:document:%d:%s", driverID, documentType)
	if err := storage.client.Set(ctx, key, content, 0).Err(); err != nil {
		return "", err
	}
	return key, nil
}
