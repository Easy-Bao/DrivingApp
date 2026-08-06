package adapter

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	redis "github.com/redis/go-redis/v9"
)

const (
	chatRoomTTL       = 24 * time.Hour
	maxHistoryEntries = 100
)

type RedisRepository struct{ client *redis.Client }

func NewRedisRepository(client *redis.Client) *RedisRepository {
	return &RedisRepository{client: client}
}

func (repository *RedisRepository) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	_, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.HSet(ctx, roomKey(roomID), map[string]any{"passenger_id": passengerID, "driver_id": driverID, "locked": "0"})
		pipe.Expire(ctx, roomKey(roomID), chatRoomTTL)
		pipe.Expire(ctx, messagesKey(roomID), chatRoomTTL)
		return nil
	})
	return err
}

func (repository *RedisRepository) Append(ctx context.Context, message domain.Message) error {
	if message.CreatedAt == "" {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	}
	payload, err := json.Marshal(map[string]string{"text": message.Body, "message": message.Body, "sender_id": message.SenderID, "senderId": message.SenderID, "created_at": message.CreatedAt, "createdAt": message.CreatedAt})
	if err != nil {
		return err
	}
	_, err = repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.RPush(ctx, messagesKey(message.RoomID), payload)
		pipe.LTrim(ctx, messagesKey(message.RoomID), -maxHistoryEntries, -1)
		pipe.Expire(ctx, messagesKey(message.RoomID), chatRoomTTL)
		return nil
	})
	return err
}

func (repository *RedisRepository) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	items, err := repository.client.LRange(ctx, messagesKey(roomID), -maxHistoryEntries, -1).Result()
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

func (repository *RedisRepository) IsMember(ctx context.Context, roomID, userID string) (bool, error) {
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return false, err
	}
	return fields["passenger_id"] == userID || fields["driver_id"] == userID, nil
}

func roomKey(roomID string) string     { return fmt.Sprintf("chat:room:%s", roomID) }
func messagesKey(roomID string) string { return fmt.Sprintf("chat:room:%s:messages", roomID) }
