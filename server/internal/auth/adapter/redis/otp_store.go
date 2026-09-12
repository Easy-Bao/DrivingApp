package redis

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	authdomain "github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	redisclient "github.com/redis/go-redis/v9"
)

type OTPStore struct{ client *redisclient.Client }

func NewOTPStore(client *redisclient.Client) *OTPStore { return &OTPStore{client: client} }

func (store *OTPStore) Put(ctx context.Context, purpose, email, code string, ttl time.Duration) error {
	if store == nil || store.client == nil {
		return errors.New("otp store is not configured")
	}
	if err := store.client.Set(
		ctx,
		key(purpose, email),
		code,
		ttl,
	).Err(); err != nil {
		return fmt.Errorf("store otp: %w", err)
	}
	return nil
}

func (store *OTPStore) Consume(ctx context.Context, purpose, email, code string) error {
	if store == nil || store.client == nil {
		return errors.New("otp store is not configured")
	}
	result, err := consumeScript.Run(
		ctx,
		store.client,
		[]string{key(purpose, email)},
		code,
	).Int()
	if err != nil {
		return fmt.Errorf("consume otp: %w", err)
	}
	if result != 1 {
		return authdomain.ErrInvalidOTP
	}
	return nil
}

var consumeScript = redisclient.NewScript(`
local value = redis.call("GET", KEYS[1])
if not value then return 0 end
if value ~= ARGV[1] then return -1 end
redis.call("DEL", KEYS[1])
return 1
`)

func key(purpose, email string) string {
	return "auth:otp:" + purpose + ":" + strings.ToLower(strings.TrimSpace(email))
}
