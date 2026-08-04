package adapter

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	redis "github.com/redis/go-redis/v9"
)

type RedisRepository struct{ client *redis.Client }

func NewRedisRepository(client *redis.Client) *RedisRepository {
	return &RedisRepository{client: client}
}

func (repository *RedisRepository) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	return repository.client.HSet(ctx, roomKey(roomID), map[string]any{"passenger_id": passengerID, "driver_id": driverID, "locked": "0"}).Err()
}

func (repository *RedisRepository) Append(ctx context.Context, message domain.Message) error {
	if message.CreatedAt == "" {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	}
	payload, err := json.Marshal(map[string]string{"text": message.Body, "message": message.Body, "sender_id": message.SenderID, "senderId": message.SenderID, "created_at": message.CreatedAt, "createdAt": message.CreatedAt})
	if err != nil {
		return err
	}
	return repository.client.RPush(ctx, messagesKey(message.RoomID), payload).Err()
}

func (repository *RedisRepository) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	items, err := repository.client.LRange(ctx, messagesKey(roomID), 0, -1).Result()
	if err != nil {
		return nil, err
	}
	result := make([]domain.Message, 0, len(items))
	for _, item := range items {
		var value struct {
			Text      string `json:"text"`
			Message   string `json:"message"`
			SenderID  string `json:"sender_id"`
			CreatedAt string `json:"created_at"`
		}
		if json.Unmarshal([]byte(item), &value) != nil {
			continue
		}
		body := value.Text
		if body == "" {
			body = value.Message
		}
		result = append(result, domain.Message{RoomID: roomID, SenderID: value.SenderID, Body: body, CreatedAt: value.CreatedAt})
	}
	return result, nil
}

func (repository *RedisRepository) Resolve(ctx context.Context, roomID string) error {
	return repository.client.HSet(ctx, roomKey(roomID), "locked", "1").Err()
}

func roomKey(roomID string) string     { return fmt.Sprintf("chat:room:%s", roomID) }
func messagesKey(roomID string) string { return fmt.Sprintf("chat:room:%s:messages", roomID) }
