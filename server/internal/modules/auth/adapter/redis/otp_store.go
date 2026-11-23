package redis

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	authports "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	authdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
	redisclient "github.com/redis/go-redis/v9"
)

type OTPStore struct {
	client *redisclient.Client
	secret []byte
}

var _ authports.OTPStore = (*OTPStore)(nil)

func NewOTPStore(client *redisclient.Client) *OTPStore { return &OTPStore{client: client} }

func (store *OTPStore) WithHashSecret(secret string) *OTPStore {
	if store != nil && secret != "" {
		store.secret = []byte(secret)
	}
	return store
}

func (store *OTPStore) Put(ctx context.Context, purpose, email, code string, ttl time.Duration) error {
	if store == nil || store.client == nil {
		return errors.New("otp store is not configured")
	}
	if ttl <= 0 || ttl.Milliseconds() <= 0 {
		return errors.New("otp ttl must be positive")
	}
	if err := _putScript.Run(
		ctx,
		store.client,
		[]string{key(purpose, email), attemptKey(purpose, email)},
		store.codeDigest(purpose, email, code),
		ttl.Milliseconds(),
	).Err(); err != nil {
		return fmt.Errorf("store otp: %w", err)
	}
	return nil
}

func (store *OTPStore) Verify(ctx context.Context, purpose, email, code string) error {
	if store == nil || store.client == nil {
		return errors.New("otp store is not configured")
	}
	result, err := _verifyScript.Run(
		ctx,
		store.client,
		[]string{key(purpose, email), attemptKey(purpose, email)},
		store.codeDigest(purpose, email, code),
		authdomain.MaxOTPVerificationAttempts,
		int64((15 * time.Minute).Milliseconds()),
	).Int()
	if err != nil {
		return fmt.Errorf("verify otp: %w", err)
	}
	switch result {
	case 1:
		return nil
	case -2:
		slog.WarnContext(ctx, "OTP code invalidated after maximum verification attempts", "purpose", purpose)
		return authdomain.ErrOTPMaxAttemptsExceeded
	default:
		return authdomain.ErrInvalidOTP
	}
}

func (store *OTPStore) Consume(ctx context.Context, purpose, email, code string) error {
	if store == nil || store.client == nil {
		return errors.New("otp store is not configured")
	}
	result, err := _consumeScript.Run(
		ctx,
		store.client,
		[]string{key(purpose, email), attemptKey(purpose, email)},
		store.codeDigest(purpose, email, code),
		authdomain.MaxOTPVerificationAttempts,
		int64((15 * time.Minute).Milliseconds()),
	).Int()
	if err != nil {
		return fmt.Errorf("consume otp: %w", err)
	}
	switch result {
	case 1:
		return nil
	case -2:
		slog.WarnContext(ctx, "OTP code invalidated after maximum verification attempts", "purpose", purpose)
		return authdomain.ErrOTPMaxAttemptsExceeded
	default:
		return authdomain.ErrInvalidOTP
	}
}

func (store *OTPStore) Delete(ctx context.Context, purpose, email string) error {
	if store == nil || store.client == nil {
		return errors.New("otp store is not configured")
	}
	if err := store.client.Del(ctx, key(purpose, email), attemptKey(purpose, email)).Err(); err != nil {
		return fmt.Errorf("delete otp: %w", err)
	}
	return nil
}

func (store *OTPStore) codeDigest(purpose, email, code string) string {
	material := "auth-otp-v1\x00" + purpose + "\x00" + strings.ToLower(strings.TrimSpace(email)) + "\x00" + code
	if store != nil && len(store.secret) > 0 {
		mac := hmac.New(sha256.New, store.secret)
		_, _ = mac.Write([]byte(material))
		return hex.EncodeToString(mac.Sum(nil))
	}
	sum := sha256.Sum256([]byte(material))
	return hex.EncodeToString(sum[:])
}

var _putScript = redisclient.NewScript(`
redis.call("SET", KEYS[1], ARGV[1], "PX", ARGV[2])
redis.call("DEL", KEYS[2])
return 1
`)

var _verifyScript = redisclient.NewScript(`
local value = redis.call("GET", KEYS[1])
if not value then
  redis.call("DEL", KEYS[2])
  return 0
end
if value ~= ARGV[1] then
  local attempts = redis.call("INCR", KEYS[2])
  if attempts == 1 then
    local ttl = redis.call("PTTL", KEYS[1])
    if ttl <= 0 then ttl = tonumber(ARGV[3]) end
    redis.call("PEXPIRE", KEYS[2], ttl)
  end
  if attempts >= tonumber(ARGV[2]) then
    redis.call("DEL", KEYS[1], KEYS[2])
    return -2
  end
  return -1
end
return 1
`)

var _consumeScript = redisclient.NewScript(`
local value = redis.call("GET", KEYS[1])
if not value then
  redis.call("DEL", KEYS[2])
  return 0
end
if value ~= ARGV[1] then
  local attempts = redis.call("INCR", KEYS[2])
  if attempts == 1 then
    local ttl = redis.call("PTTL", KEYS[1])
    if ttl <= 0 then ttl = tonumber(ARGV[3]) end
    redis.call("PEXPIRE", KEYS[2], ttl)
  end
  if attempts >= tonumber(ARGV[2]) then
    redis.call("DEL", KEYS[1], KEYS[2])
    return -2
  end
  return -1
end
redis.call("DEL", KEYS[1], KEYS[2])
return 1
`)

func attemptKey(purpose, email string) string {
	return key(purpose, email) + ":attempts"
}

func key(purpose, email string) string {
	return "auth:otp:" + purpose + ":" + strings.ToLower(strings.TrimSpace(email))
}
