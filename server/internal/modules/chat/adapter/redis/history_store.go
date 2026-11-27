package redis

import (
	"context"
	"errors"
	"fmt"
	chatapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	redis "github.com/redis/go-redis/v9"
	"strconv"
	"time"
)

const (
	_defaultActiveRoomTTL   = 24 * time.Hour
	_defaultResolvedRoomTTL = 1 * time.Hour
	_defaultMaxMessages     = 1000
	_roomKeyPrefix          = "chat:room:"
	_messagesKeySuffix      = ":messages"
)

var (
	// _createRoomScript atomically preserves existing participants and lock state on concurrent opens
	// while enforcing a finite TTL for volatile-lru memory safety.
	_createRoomScript = redis.NewScript(`
if redis.call('EXISTS', KEYS[1]) == 0 then
	redis.call('HSET', KEYS[1], 'passenger_id', ARGV[1], 'driver_id', ARGV[2], 'locked', '0', 'has_messages', '0')
end
local ttl = tonumber(ARGV[3])
if ttl and ttl > 0 then
	redis.call('EXPIRE', KEYS[1], ttl)
	if redis.call('EXISTS', KEYS[2]) == 1 then
		redis.call('EXPIRE', KEYS[2], ttl)
	end
end
return 1
`)

	// _appendMessageScript checks room existence, lock state, and membership
	// atomically with appending, bounds the list length, refreshes finite TTLs,
	// and returns the room's participants in one RTT.
	_appendMessageScript = redis.NewScript(`
if redis.call('EXISTS', KEYS[1]) == 0 then
	return {'-1'}
end
local fields = redis.call('HMGET', KEYS[1], 'locked', 'passenger_id', 'driver_id')
if fields[1] == '1' then
	return {'-2'}
end
local passenger = fields[2] or ''
local driver = fields[3] or ''
if passenger ~= ARGV[1] and driver ~= ARGV[1] then
	return {'-3'}
end
redis.call('RPUSH', KEYS[2], ARGV[2])
local max_messages = tonumber(ARGV[4])
if max_messages and max_messages > 0 then
	redis.call('LTRIM', KEYS[2], -max_messages, -1)
end
redis.call('HSET', KEYS[1], 'has_messages', '1')
local ttl = tonumber(ARGV[3])
if ttl and ttl > 0 then
	redis.call('EXPIRE', KEYS[1], ttl)
	redis.call('EXPIRE', KEYS[2], ttl)
end
return {'1', passenger, driver}
`)

	// _markReadScript advances a participant's read watermark monotonically.
	// Fixed-width UTC timestamps compare chronologically.
	_markReadScript = redis.NewScript(`
if redis.call('EXISTS', KEYS[1]) == 0 then
	return 0
end
local previous = redis.call('HGET', KEYS[1], ARGV[1])
if not previous or previous < ARGV[2] then
	redis.call('HSET', KEYS[1], ARGV[1], ARGV[2])
end
local ttl = tonumber(ARGV[3])
if ttl and ttl > 0 then
	redis.call('EXPIRE', KEYS[1], ttl)
end
return 1
`)
)

// StoredRoomState represents Redis metadata for a cached or legacy chat room.
type StoredRoomState struct {
	RoomID               string
	PassengerID          string
	DriverID             string
	Locked               bool
	HasMessages          bool
	PassengerReadThrough string
	DriverReadThrough    string
	Messages             []domain.Message
}

type storedMessage struct {
	ID              string `json:"id"`
	ImageKey        string `json:"image_key,omitempty"`
	Text            string `json:"text"`
	LegacyMessage   string `json:"message,omitempty"`
	SenderID        string `json:"sender_id"`
	LegacySenderID  string `json:"senderId,omitempty"`
	CreatedAt       string `json:"created_at"`
	LegacyCreatedAt string `json:"createdAt,omitempty"`
}

// HistoryStore is the Redis adapter for bounded-TTL hot-cache chat room state.
type HistoryStore struct {
	client      *redis.Client
	activeTTL   time.Duration
	resolvedTTL time.Duration
	maxMessages int64
}

type Option func(*HistoryStore)

func WithActiveTTL(ttl time.Duration) Option {
	return func(store *HistoryStore) {
		if store != nil && ttl > 0 {
			store.activeTTL = ttl
		}
	}
}

func WithResolvedTTL(ttl time.Duration) Option {
	return func(store *HistoryStore) {
		if store != nil && ttl > 0 {
			store.resolvedTTL = ttl
		}
	}
}

func WithMaxMessages(limit int) Option {
	return func(store *HistoryStore) {
		if store != nil && limit > 0 {
			store.maxMessages = int64(limit)
		}
	}
}

var _ chatapp.RoomStore = (*HistoryStore)(nil)

func NewHistoryStore(client *redis.Client, options ...Option) *HistoryStore {
	store := &HistoryStore{
		client:      client,
		activeTTL:   _defaultActiveRoomTTL,
		resolvedTTL: _defaultResolvedRoomTTL,
		maxMessages: _defaultMaxMessages,
	}
	for _, option := range options {
		if option != nil {
			option(store)
		}
	}
	return store
}

// CreateRoom creates or refreshes a bounded-TTL participant-scoped room without changing its lock.
func (repository *HistoryStore) CreateRoom(ctx context.Context, roomID, passengerID, driverID string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	if err := _createRoomScript.Run(
		ctx,
		repository.client,
		[]string{roomKey(roomID), messagesKey(roomID)},
		passengerID,
		driverID,
		ttlSeconds(repository.activeDuration()),
	).Err(); err != nil {
		return fmt.Errorf("create chat room: %w", err)
	}
	return nil
}

// Append adds a message to the cached room list with bounded retention.
func (repository *HistoryStore) Append(ctx context.Context, message domain.Message) error {
	_, _, err := repository.AppendWithParticipants(ctx, message)
	return err
}

// AppendWithParticipants atomically validates room existence, lock state, and
// sender membership while appending a canonical JSON payload and returning the room's participants.
func (repository *HistoryStore) AppendWithParticipants(ctx context.Context, message domain.Message) (string, string, error) {
	if err := repository.validate(); err != nil {
		return "", "", err
	}
	payload, err := marshalCanonicalMessage(message)
	if err != nil {
		return "", "", fmt.Errorf("marshal chat message: %w", err)
	}
	values, err := _appendMessageScript.Run(
		ctx,
		repository.client,
		[]string{roomKey(message.RoomID), messagesKey(message.RoomID)},
		message.SenderID,
		string(payload),
		ttlSeconds(repository.activeDuration()),
		strconv.FormatInt(repository.messageLimit(), 10),
	).StringSlice()
	if err != nil {
		return "", "", fmt.Errorf("append chat message: %w", err)
	}
	if len(values) == 0 {
		return "", "", errors.New("append chat message: unexpected empty script result")
	}
	switch values[0] {
	case "-1":
		return "", "", domain.ErrRoomUnavailable
	case "-2":
		return "", "", domain.ErrRoomLocked
	case "-3":
		return "", "", domain.ErrForbidden
	case "1":
		var passengerID, driverID string
		if len(values) > 1 {
			passengerID = values[1]
		}
		if len(values) > 2 {
			driverID = values[2]
		}
		return passengerID, driverID, nil
	default:
		return "", "", fmt.Errorf("append chat message: unexpected script status %q", values[0])
	}
}

// Messages returns bounded recent entries from Redis when present.
func (repository *HistoryStore) Messages(ctx context.Context, roomID string) ([]domain.Message, error) {
	messages, _, err := repository.MessagesIfCached(ctx, roomID)
	return messages, err
}

// MessagesIfCached returns messages only if the room hash exists in Redis and any
// expected message list has not been evicted under volatile-lru.
func (repository *HistoryStore) MessagesIfCached(ctx context.Context, roomID string) ([]domain.Message, bool, error) {
	if err := repository.validate(); err != nil {
		return nil, false, err
	}
	var (
		fieldsCmd *redis.MapStringStringCmd
		itemsCmd  *redis.StringSliceCmd
	)
	_, err := repository.client.Pipelined(ctx, func(pipe redis.Pipeliner) error {
		fieldsCmd = pipe.HGetAll(ctx, roomKey(roomID))
		itemsCmd = pipe.LRange(ctx, messagesKey(roomID), -repository.messageLimit(), -1)
		return nil
	})
	if err != nil {
		return nil, false, fmt.Errorf("load chat messages: %w", err)
	}
	fields, err := fieldsCmd.Result()
	if err != nil {
		return nil, false, fmt.Errorf("load chat room metadata: %w", err)
	}
	if len(fields) == 0 {
		return nil, false, nil
	}
	items, err := itemsCmd.Result()
	if err != nil {
		return nil, false, fmt.Errorf("load chat messages: %w", err)
	}
	if fields["has_messages"] == "1" && len(items) == 0 {
		return nil, false, nil
	}
	return decodeStoredMessages(roomID, fields, items), true, nil
}

// FindMessage locates a single message by ID within the cached bounded history.
func (repository *HistoryStore) FindMessage(ctx context.Context, roomID, messageID string) (domain.Message, bool, error) {
	messages, hit, err := repository.MessagesIfCached(ctx, roomID)
	if err != nil || !hit {
		return domain.Message{}, false, err
	}
	for _, msg := range messages {
		if msg.ID == messageID {
			return msg, true, nil
		}
	}
	return domain.Message{}, false, nil
}

// Resolve marks a room locked and applies the finite post-resolution expiration.
func (repository *HistoryStore) Resolve(ctx context.Context, roomID string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	ttl := repository.resolvedDuration()
	_, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.HSet(ctx, roomKey(roomID), "locked", "1")
		pipe.Expire(ctx, roomKey(roomID), ttl)
		pipe.Expire(ctx, messagesKey(roomID), ttl)
		return nil
	})
	if err != nil {
		return fmt.Errorf("resolve chat room: %w", err)
	}
	return nil
}

func (repository *HistoryStore) IsMember(ctx context.Context, roomID, userID string) (bool, error) {
	if err := repository.validate(); err != nil {
		return false, err
	}
	if userID == "" {
		return false, nil
	}
	passengerID, driverID, err := repository.RoomParticipants(ctx, roomID)
	if err != nil {
		return false, err
	}
	return passengerID == userID || driverID == userID, nil
}

func (repository *HistoryStore) IsLocked(ctx context.Context, roomID string) (bool, error) {
	locked, _, err := repository.IsLockedIfCached(ctx, roomID)
	return locked, err
}

func (repository *HistoryStore) IsLockedIfCached(ctx context.Context, roomID string) (bool, bool, error) {
	if err := repository.validate(); err != nil {
		return false, false, err
	}
	value, err := repository.client.HGet(ctx, roomKey(roomID), "locked").Result()
	if errors.Is(err, redis.Nil) {
		return false, false, nil
	}
	if err != nil {
		return false, false, fmt.Errorf("read chat room lock state: %w", err)
	}
	return value == "1", true, nil
}

func (repository *HistoryStore) RoomParticipants(ctx context.Context, roomID string) (string, string, error) {
	passengerID, driverID, _, err := repository.RoomParticipantsIfCached(ctx, roomID)
	return passengerID, driverID, err
}

func (repository *HistoryStore) RoomParticipantsIfCached(ctx context.Context, roomID string) (string, string, bool, error) {
	if err := repository.validate(); err != nil {
		return "", "", false, err
	}
	values, err := repository.client.HMGet(ctx, roomKey(roomID), "passenger_id", "driver_id").Result()
	if err != nil {
		return "", "", false, fmt.Errorf("load chat room participants: %w", err)
	}
	var passengerID, driverID string
	if len(values) > 0 {
		passengerID = hashString(values[0])
	}
	if len(values) > 1 {
		driverID = hashString(values[1])
	}
	if passengerID == "" && driverID == "" {
		return "", "", false, nil
	}
	return passengerID, driverID, true, nil
}

func (repository *HistoryStore) MarkRead(ctx context.Context, roomID, userID, through string) error {
	if err := repository.validate(); err != nil {
		return err
	}
	return _markReadScript.Run(
		ctx,
		repository.client,
		[]string{roomKey(roomID)},
		"read:"+userID,
		through,
		ttlSeconds(repository.activeDuration()),
	).Err()
}

// WarmRoom repopulates Redis hot cache with finite TTL from authoritative storage.
func (repository *HistoryStore) WarmRoom(ctx context.Context, state StoredRoomState) error {
	if err := repository.validate(); err != nil {
		return err
	}
	ttl := repository.activeDuration()
	if state.Locked {
		ttl = repository.resolvedDuration()
	}
	hasMessages := "0"
	encodedMessages := make([]any, 0, len(state.Messages))
	if len(state.Messages) > 0 {
		hasMessages = "1"
		start := 0
		if maxLen := int(repository.messageLimit()); len(state.Messages) > maxLen {
			start = len(state.Messages) - maxLen
		}
		for _, msg := range state.Messages[start:] {
			payload, err := marshalCanonicalMessage(msg)
			if err != nil {
				return fmt.Errorf("marshal warmed message: %w", err)
			}
			encodedMessages = append(encodedMessages, string(payload))
		}
	}
	lockedValue := "0"
	if state.Locked {
		lockedValue = "1"
	}
	fields := map[string]any{
		"passenger_id": state.PassengerID,
		"driver_id":    state.DriverID,
		"locked":       lockedValue,
		"has_messages": hasMessages,
	}
	if state.PassengerReadThrough != "" && state.PassengerID != "" {
		fields["read:"+state.PassengerID] = state.PassengerReadThrough
	}
	if state.DriverReadThrough != "" && state.DriverID != "" {
		fields["read:"+state.DriverID] = state.DriverReadThrough
	}

	rKey := roomKey(state.RoomID)
	mKey := messagesKey(state.RoomID)
	_, err := repository.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.HSet(ctx, rKey, fields)
		pipe.Expire(ctx, rKey, ttl)
		if len(encodedMessages) > 0 {
			pipe.Del(ctx, mKey)
			pipe.RPush(ctx, mKey, encodedMessages...)
			pipe.Expire(ctx, mKey, ttl)
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("warm chat cache: %w", err)
	}
	return nil
}

func (repository *HistoryStore) activeDuration() time.Duration {
	if repository != nil && repository.activeTTL > 0 {
		return repository.activeTTL
	}
	return _defaultActiveRoomTTL
}

func (repository *HistoryStore) resolvedDuration() time.Duration {
	if repository != nil && repository.resolvedTTL > 0 {
		return repository.resolvedTTL
	}
	return _defaultResolvedRoomTTL
}

func (repository *HistoryStore) messageLimit() int64 {
	if repository != nil && repository.maxMessages > 0 {
		return repository.maxMessages
	}
	return _defaultMaxMessages
}

func ttlSeconds(d time.Duration) int64 {
	secs := int64(d.Seconds())
	if secs <= 0 {
		return 1
	}
	return secs
}

func hashString(value any) string {
	if text, ok := value.(string); ok {
		return text
	}
	return ""
}

func roomKey(roomID string) string     { return _roomKeyPrefix + roomID }
func messagesKey(roomID string) string { return _roomKeyPrefix + roomID + _messagesKeySuffix }

func (repository *HistoryStore) validate() error {
	if repository == nil || repository.client == nil {
		return errors.New("chat history store is not configured")
	}
	return nil
}
