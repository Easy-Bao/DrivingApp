package storage

import (
	"context"
	"fmt"
	"strings"

	redisclient "github.com/redis/go-redis/v9"
)

type RedisLegacyReader struct {
	client *redisclient.Client
}

func NewRedisLegacyReader(client *redisclient.Client) *RedisLegacyReader {
	return &RedisLegacyReader{client: client}
}

func (reader *RedisLegacyReader) Read(ctx context.Context, key string, maxBytes int64) ([]byte, error) {
	if reader == nil || reader.client == nil || !strings.HasPrefix(key, "driver:document:") {
		return nil, fmt.Errorf("invalid legacy driver document object key")
	}
	content, err := reader.client.GetRange(ctx, key, 0, maxBytes).Bytes()
	if err != nil {
		return nil, fmt.Errorf("read legacy driver document object: %w", err)
	}
	if len(content) == 0 || int64(len(content)) > maxBytes {
		return nil, fmt.Errorf("legacy driver document object has an invalid size")
	}
	return content, nil
}
