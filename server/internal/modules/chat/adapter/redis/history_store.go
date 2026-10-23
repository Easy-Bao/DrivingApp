package redis

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	chatapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	redis "github.com/redis/go-redis/v9"
)

// HistoryStore is the Redis adapter for the retained chat-room history port.
type HistoryStore struct{ client *redis.Client }

var _ chatapp.RoomStore = (*HistoryStore)(nil)

func NewHistoryStore(client *redis.Client) *HistoryStore {
	return &HistoryStore{client: client}
}

// CreateRoom creates a retained participant-scoped room without changing its lock.
func (repository *HistoryStore) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	// Atomically preserve existing participants and lock state on concurrent opens.
	const script = `if redis.call('EXISTS', KEYS[1]) == 0 then
 redis.call('HSET', KEYS[1], 'passenger_id', ARGV[1], 'driver_id', ARGV[2], 'locked', '0') end
 redis.call('PERSIST', KEYS[1])
 redis.call('PERSIST', KEYS[2])
 return 1`
	if err := repository.client.Eval(ctx, script, []string{roomKey(roomID), messagesKey(roomID)}, passengerID, driverID).Err(); err != nil {
		return fmt.Errorf("create chat room: %w", err)
	}
	return nil
}

// Append retains messages independently of the sending window.
func (repository *HistoryStore) Append(ctx context.Context, message domain.Message) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if message.CreatedAt == "" {
		message.CreatedAt = time.Now().UTC().Format(time.RFC3339Nano)
	}
	payload, err := json.Marshal(map[string]string{
		"id":         message.ID,
		"image_key":  message.ImageKey,
		"text":       message.Body,
		"message":    message.Body,
		"sender_id":  message.SenderID,
		"senderId":   message.SenderID,
		"created_at": message.CreatedAt,
		"createdAt":  message.CreatedAt,
	})
	if err != nil {
		return fmt.Errorf("marshal chat message: %w", err)
	}
	// The lock and membership check shares the append operation so resolving a
	// conversation cannot race with an accepted message or picture.
	const script = `if redis.call('EXISTS', KEYS[1]) == 0 then return -1 end
 if redis.call('HGET', KEYS[1], 'locked') == '1' then return -2 end
 if redis.call('HGET', KEYS[1], 'passenger_id') ~= ARGV[1] and redis.call('HGET', KEYS[1], 'driver_id') ~= ARGV[1] then return -3 end
 redis.call('RPUSH', KEYS[2], ARGV[2])
 redis.call('PERSIST', KEYS[1])
 redis.call('PERSIST', KEYS[2])
 return 1`
	result, err := repository.client.Eval(ctx, script, []string{roomKey(message.RoomID), messagesKey(message.RoomID)}, message.SenderID, string(payload)).Int()
	if err != nil {
		return fmt.Errorf("append chat message: %w", err)
	}
	switch result {
	case -1:
		return domain.ErrRoomUnavailable
	case -2:
		return domain.ErrRoomLocked
	case -3:
		return domain.ErrForbidden
	}
	return nil
}

// Messages returns valid entries from the retained room history. Malformed
// stored entries are ignored so one bad record cannot hide later messages.
func (repository *HistoryStore) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	if err := repository.retain(ctx, roomID); err != nil {
		return nil, err
	}
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return nil, err
	}
	items, err := repository.client.LRange(ctx, messagesKey(roomID), 0, -1).Result()
	if err != nil {
		return nil, fmt.Errorf("load chat messages: %w", err)
	}
	result := make([]domain.Message, 0, len(items))
	for _, item := range items {
		var value struct {
			ID        string `json:"id"`
			ImageKey  string `json:"image_key"`
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
		if value.ID == "" {
			value.ID = fmt.Sprintf("legacy-%x", sha256.Sum256([]byte(value.SenderID+"\n"+value.CreatedAt+"\n"+body)))
		}
		peerID := fields["passenger_id"]
		if value.SenderID == peerID {
			peerID = fields["driver_id"]
		}
		created, _ := time.Parse(time.RFC3339Nano, value.CreatedAt)
		through, _ := time.Parse(time.RFC3339Nano, fields["read:"+peerID])
		result = append(result, domain.Message{
			ID: value.ID, ImageKey: value.ImageKey, Seen: !created.IsZero() && !through.IsZero() && !created.After(through),
			RoomID:    roomID,
			SenderID:  value.SenderID,
			Body:      body,
			CreatedAt: value.CreatedAt,
		})
	}
	return result, nil
}

// Resolve marks a room closed for the service's subsequent message checks.
func (repository *HistoryStore) Resolve(ctx context.Context, roomID string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if err := repository.client.HSet(ctx, roomKey(roomID), "locked", "1").Err(); err != nil {
		return fmt.Errorf("resolve chat room: %w", err)
	}
	return nil
}

func (repository *HistoryStore) IsMember(ctx context.Context, roomID, userID string) (bool, error) {
	if err := repository.validate(); err != nil {
		return false, err
	}
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return false, fmt.Errorf("load chat room participants: %w", err)
	}
	return fields["passenger_id"] == userID || fields["driver_id"] == userID, nil
}

func (repository *HistoryStore) IsLocked(ctx context.Context, roomID string) (bool, error) {
	if err := repository.validate(); err != nil {
		return false, err
	}
	value, err := repository.client.HGet(ctx, roomKey(roomID), "locked").Result()
	if errors.Is(err, redis.Nil) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("read chat room lock state: %w", err)
	}
	return value == "1", nil
}

func (repository *HistoryStore) RoomParticipants(ctx context.Context, roomID string) (string, string, error) {
	if err := repository.validate(); err != nil {
		return "", "", err
	}
	fields, err := repository.client.HGetAll(ctx, roomKey(roomID)).Result()
	if err != nil {
		return "", "", fmt.Errorf("load chat room participants: %w", err)
	}
	return fields["passenger_id"], fields["driver_id"], nil
}

func roomKey(roomID string) string     { return "chat:room:" + roomID }
func messagesKey(roomID string) string { return "chat:room:" + roomID + ":messages" }

func (repository *HistoryStore) validate() error {
	if repository == nil || repository.client == nil {
		return errors.New("chat history store is not configured")
	}
	return nil
}

// retain upgrades still-available legacy rooms without reopening them.
func (repository *HistoryStore) retain(ctx context.Context, roomID string) error {
	_, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.Persist(ctx, roomKey(roomID))
		pipe.Persist(ctx, messagesKey(roomID))
		return nil
	})
	return err
}

func (repository *HistoryStore) MarkRead(ctx context.Context, roomID, userID, through string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	// Fixed-width UTC timestamps compare chronologically. Older acknowledgements
	// from another device must never move the watermark backwards.
	const script = `local previous = redis.call('HGET', KEYS[1], ARGV[1])
 if not previous or previous < ARGV[2] then
 redis.call('HSET', KEYS[1], ARGV[1], ARGV[2]) end
 return 1`
	return repository.client.Eval(ctx, script, []string{roomKey(roomID)}, "read:"+userID, through).Err()
}

// RetainExistingHistory removes the former expiry from still-available chat
// records before traffic starts, including conversations not opened again yet.
func (repository *HistoryStore) RetainExistingHistory(ctx context.Context) error {
	if err := repository.validate(); err != nil {
		return err
	}
	var cursor uint64
	for {
		keys, next, err := repository.client.Scan(ctx, cursor, "chat:room:*", 200).Result()
		if err != nil {
			return fmt.Errorf("scan legacy chat history: %w", err)
		}
		if len(keys) > 0 {
			_, err = repository.client.Pipelined(ctx, func(pipe redis.Pipeliner) error {
				for _, key := range keys {
					pipe.Persist(ctx, key)
				}
				return nil
			})
			if err != nil {
				return fmt.Errorf("retain legacy chat history: %w", err)
			}
		}
		if next == 0 {
			return nil
		}
		cursor = next
	}
}
