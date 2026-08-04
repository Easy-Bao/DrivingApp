package redis

import (
	"context"
	"fmt"
	"strings"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

type OTPStore struct{ client *redisclient.Client }

func NewOTPStore(client *redisclient.Client) *OTPStore { return &OTPStore{client: client} }

func (store *OTPStore) Put(ctx context.Context, purpose, email, code string, ttl time.Duration) error {
	return store.client.Set(ctx, key(purpose, email), code, ttl).Err()
}

func (store *OTPStore) Consume(ctx context.Context, purpose, email, code string) error {
	result, err := consumeScript.Run(ctx, store.client, []string{key(purpose, email)}, code).Int()
	if err != nil || result != 1 {
		return fmt.Errorf("otp was not accepted")
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
