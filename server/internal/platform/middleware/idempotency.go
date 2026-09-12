package middleware

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"sync"
	"time"

	redisclient "github.com/redis/go-redis/v9"
)

type IdempotencyStore interface {
	Get(ctx context.Context, key string) ([]byte, error)
	Set(ctx context.Context, key string, value []byte, expiration time.Duration) error
	SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error)
	DeleteIfValue(ctx context.Context, key string, value []byte) error
}

type RedisIdempotencyStore struct {
	client *redisclient.Client
}

func NewRedisIdempotencyStore(client *redisclient.Client) *RedisIdempotencyStore {
	return &RedisIdempotencyStore{client: client}
}

func (store *RedisIdempotencyStore) Get(ctx context.Context, key string) ([]byte, error) {
	if store == nil || store.client == nil {
		return nil, fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return nil, errors.New("idempotency context is nil")
	}
	value, err := store.client.Get(ctx, key).Bytes()
	if errors.Is(err, redisclient.Nil) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get idempotency response: %w", err)
	}
	return value, nil
}

func (store *RedisIdempotencyStore) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	if store == nil || store.client == nil {
		return fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return errors.New("idempotency context is nil")
	}
	if err := store.client.Set(
		ctx,
		key,
		value,
		expiration,
	).Err(); err != nil {
		return fmt.Errorf("set idempotency response: %w", err)
	}
	return nil
}

func (store *RedisIdempotencyStore) SetNX(
	ctx context.Context,
	key string,
	value []byte,
	expiration time.Duration,
) (bool, error) {
	if store == nil || store.client == nil {
		return false, fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return false, errors.New("idempotency context is nil")
	}
	acquired, err := store.client.SetNX(
		ctx,
		key,
		value,
		expiration,
	).Result()
	if err != nil {
		return false, fmt.Errorf("acquire idempotency lock: %w", err)
	}
	return acquired, nil
}

func (store *RedisIdempotencyStore) DeleteIfValue(ctx context.Context, key string, value []byte) error {
	if store == nil || store.client == nil {
		return fmt.Errorf("redis idempotency store is not configured")
	}
	if ctx == nil {
		return errors.New("idempotency context is nil")
	}
	const releaseLockScript = `
if redis.call("GET", KEYS[1]) == ARGV[1] then
    return redis.call("DEL", KEYS[1])
else
    return 0
end`
	if err := store.client.Eval(
		ctx,
		releaseLockScript,
		[]string{key},
		value,
	).Err(); err != nil {
		return fmt.Errorf("release idempotency lock: %w", err)
	}
	return nil
}

type MemoryIdempotencyStore struct {
	mu      sync.Mutex
	entries map[string]memoryIdempotencyEntry
}

type memoryIdempotencyEntry struct {
	value   []byte
	expires time.Time
}

func NewMemoryIdempotencyStore() *MemoryIdempotencyStore {
	return &MemoryIdempotencyStore{entries: make(map[string]memoryIdempotencyEntry)}
}

func (store *MemoryIdempotencyStore) Get(ctx context.Context, key string) ([]byte, error) {
	if store == nil {
		return nil, errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return nil, err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	entry, ok := store.entries[key]
	if !ok || !time.Now().Before(entry.expires) {
		delete(store.entries, key)
		return nil, nil
	}
	return append([]byte(nil), entry.value...), nil
}

func (store *MemoryIdempotencyStore) Set(
	ctx context.Context,
	key string,
	value []byte,
	expiration time.Duration,
) error {
	if store == nil {
		return errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.entries == nil {
		store.entries = make(map[string]memoryIdempotencyEntry)
	}
	store.entries[key] = memoryIdempotencyEntry{value: append([]byte(nil), value...), expires: time.Now().Add(expiration)}
	return nil
}

func (store *MemoryIdempotencyStore) SetNX(
	ctx context.Context,
	key string,
	value []byte,
	expiration time.Duration,
) (bool, error) {
	if store == nil {
		return false, errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return false, err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.entries == nil {
		store.entries = make(map[string]memoryIdempotencyEntry)
	}
	now := time.Now()
	if entry, ok := store.entries[key]; ok && now.Before(entry.expires) {
		return false, nil
	}
	store.entries[key] = memoryIdempotencyEntry{value: append([]byte(nil), value...), expires: now.Add(expiration)}
	return true, nil
}

func (store *MemoryIdempotencyStore) DeleteIfValue(ctx context.Context, key string, value []byte) error {
	if store == nil {
		return errors.New("memory idempotency store is not configured")
	}
	if err := memoryIdempotencyContextError(ctx); err != nil {
		return err
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	entry, ok := store.entries[key]
	if ok && bytes.Equal(entry.value, value) {
		delete(store.entries, key)
	}
	return nil
}

type Idempotency struct {
	store       IdempotencyStore
	expiration  time.Duration
	lockTimeout time.Duration
	logger      *slog.Logger
}

const maxIdempotencyBodyBytes int64 = 10 << 20

func NewIdempotency(store IdempotencyStore, expiration time.Duration) *Idempotency {
	if expiration <= 0 {
		expiration = 10 * time.Minute
	}
	return &Idempotency{
		store:       store,
		expiration:  expiration,
		lockTimeout: time.Minute,
		logger:      slog.Default(),
	}
}

func (idempotency *Idempotency) WithLogger(logger *slog.Logger) *Idempotency {
	if idempotency != nil && logger != nil {
		idempotency.logger = logger
	}
	return idempotency
}

func (idempotency *Idempotency) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if idempotency == nil {
			next.ServeHTTP(writer, request)
			return
		}
		if idempotency.store == nil || !supportsIdempotency(request) {
			next.ServeHTTP(writer, request)
			return
		}
		idempotencyKey := strings.TrimSpace(request.Header.Get("Idempotency-Key"))
		if idempotencyKey == "" {
			next.ServeHTTP(writer, request)
			return
		}
		if !validIdempotencyKey(idempotencyKey) {
			writeSecurityError(writer, http.StatusBadRequest, "invalid idempotency key")
			return
		}

		var body []byte
		if request.Body != nil {
			request.Body = http.MaxBytesReader(writer, request.Body, maxIdempotencyBodyBytes)
			var err error
			body, err = io.ReadAll(request.Body)
			if err != nil {
				writeSecurityError(writer, http.StatusRequestEntityTooLarge, "request body is too large")
				return
			}
		}
		request.Body = io.NopCloser(bytes.NewReader(body))
		fingerprint := requestFingerprint(request, body)
		baseKey := "idempotency:" + requestTargetScope(request) + ":" + authorizationScope(request) + ":" + idempotencyKey
		resultKey := baseKey + ":result"
		lockKey := baseKey + ":lock"

		cached, err := idempotency.store.Get(request.Context(), resultKey)
		if err != nil {
			writer.Header().Set("Retry-After", "1")
			writeSecurityError(writer, http.StatusServiceUnavailable, "request protection is temporarily unavailable")
			return
		}
		if len(cached) > 0 {
			replayIdempotentResponse(writer, cached, fingerprint)
			return
		}
		lockToken, err := newLockToken()
		if err != nil {
			writer.Header().Set("Retry-After", "1")
			writeSecurityError(writer, http.StatusServiceUnavailable, "request protection is temporarily unavailable")
			return
		}
		acquired, err := idempotency.store.SetNX(
			request.Context(),
			lockKey,
			lockToken,
			idempotency.lockTimeout,
		)
		if err != nil {
			writer.Header().Set("Retry-After", "1")
			writeSecurityError(writer, http.StatusServiceUnavailable, "request protection is temporarily unavailable")
			return
		}
		if !acquired {
			writeSecurityError(writer, http.StatusConflict, "request with this idempotency key is already in progress")
			return
		}
		defer idempotency.releaseLock(request, lockKey, lockToken)

		capture := &idempotentResponseWriter{ResponseWriter: writer}
		next.ServeHTTP(capture, request)
		if capture.status >= http.StatusOK && capture.status < http.StatusInternalServerError {
			record, marshalErr := json.Marshal(idempotentResponse{
				Fingerprint: fingerprint,
				Status:      capture.status,
				Headers:     cloneHeaders(capture.Header()),
				Body:        capture.body.Bytes(),
			})
			if marshalErr != nil {
				idempotency.log().ErrorContext(request.Context(), "encode idempotency response failed", "error", marshalErr)
			} else {
				resultContext, cancel := context.WithTimeout(context.WithoutCancel(request.Context()), time.Second)
				setErr := idempotency.store.Set(
					resultContext,
					resultKey,
					record,
					idempotency.expiration,
				)
				cancel()
				if setErr != nil {
					idempotency.log().WarnContext(
						request.Context(),
						"store idempotency response failed",
						"error",
						setErr,
						"key_hash",
						hashIdempotencyKey(idempotencyKey),
					)
				}
			}
		}
	})
}

func (idempotency *Idempotency) releaseLock(request *http.Request, key string, token []byte) {
	cleanupContext, cancel := context.WithTimeout(context.WithoutCancel(request.Context()), time.Second)
	defer cancel()
	if err := idempotency.store.DeleteIfValue(cleanupContext, key, token); err != nil {
		idempotency.log().WarnContext(
			request.Context(),
			"release idempotency lock failed",
			"error",
			err,
			"key_hash",
			hashIdempotencyKey(request.Header.Get("Idempotency-Key")),
		)
	}
}

func (idempotency *Idempotency) log() *slog.Logger {
	if idempotency != nil && idempotency.logger != nil {
		return idempotency.logger
	}
	return slog.Default()
}

func memoryIdempotencyContextError(ctx context.Context) error {
	if ctx == nil {
		return errors.New("idempotency context is nil")
	}
	return ctx.Err()
}

type idempotentResponse struct {
	Fingerprint string              `json:"fingerprint"`
	Status      int                 `json:"status"`
	Headers     map[string][]string `json:"headers"`
	Body        []byte              `json:"body"`
}

type idempotentResponseWriter struct {
	http.ResponseWriter
	body   bytes.Buffer
	status int
}

func (writer *idempotentResponseWriter) WriteHeader(status int) {
	if writer.status != 0 {
		return
	}
	writer.status = status
	writer.ResponseWriter.WriteHeader(status)
}

func (writer *idempotentResponseWriter) Write(body []byte) (int, error) {
	if writer.status == 0 {
		writer.WriteHeader(http.StatusOK)
	}
	if _, err := writer.body.Write(body); err != nil {
		slog.Error("capture idempotent response body failed", "error", err)
	}
	return writer.ResponseWriter.Write(body)
}

func replayIdempotentResponse(writer http.ResponseWriter, encoded []byte, fingerprint string) {
	var response idempotentResponse
	if err := json.Unmarshal(encoded, &response); err != nil {
		slog.Debug("decode cached idempotency response failed", "error", err)
		writeSecurityError(writer, http.StatusConflict, "idempotency key was used with a different request")
		return
	}
	if response.Fingerprint != fingerprint {
		writeSecurityError(writer, http.StatusConflict, "idempotency key was used with a different request")
		return
	}
	for key, values := range response.Headers {
		writer.Header()[key] = append([]string(nil), values...)
	}
	writer.WriteHeader(response.Status)
	if _, err := writer.Write(response.Body); err != nil {
		slog.Debug("replay idempotent response failed", "error", err)
	}
}

func supportsIdempotency(request *http.Request) bool {
	return classifyEndpoint(request) == endpointCommand
}

func authorizationScope(request *http.Request) string {
	hash := sha256.Sum256([]byte(strings.TrimSpace(request.Header.Get("Authorization"))))
	return hex.EncodeToString(hash[:])
}

func requestTargetScope(request *http.Request) string {
	hash := sha256.Sum256([]byte(request.Method + "\n" + request.URL.RequestURI()))
	return hex.EncodeToString(hash[:])
}

func validIdempotencyKey(value string) bool {
	return len(value) >= 8 && len(value) <= 128 && !containsControlCharacter(value)
}

func requestFingerprint(request *http.Request, body []byte) string {
	authorization := authorizationScope(request)
	value := make([]byte, 0, len(request.Method)+len(request.URL.RequestURI())+len(body)+len(authorization)+3)
	value = append(value, request.Method...)
	value = append(value, '\n')
	value = append(value, request.URL.RequestURI()...)
	value = append(value, '\n')
	value = append(value, authorization...)
	value = append(value, '\n')
	value = append(value, body...)
	hash := sha256.Sum256(value)
	return hex.EncodeToString(hash[:])
}

func newLockToken() ([]byte, error) {
	token := make([]byte, 16)
	if _, err := rand.Read(token); err != nil {
		return nil, fmt.Errorf("generate idempotency lock token: %w", err)
	}
	return token, nil
}

func hashIdempotencyKey(key string) string {
	hash := sha256.Sum256([]byte(key))
	return hex.EncodeToString(hash[:8])
}

func cloneHeaders(headers http.Header) map[string][]string {
	clone := make(map[string][]string, len(headers))
	for key, values := range headers {
		if strings.EqualFold(key, "X-Request-ID") ||
			strings.HasPrefix(strings.ToLower(key), "x-ratelimit-") ||
			strings.EqualFold(key, "Retry-After") {
			continue
		}
		clone[key] = append([]string(nil), values...)
	}
	return clone
}
