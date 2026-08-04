package middleware

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
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
	Delete(ctx context.Context, key string) error
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
	value, err := store.client.Get(ctx, key).Bytes()
	if err == redisclient.Nil {
		return nil, nil
	}
	return value, err
}

func (store *RedisIdempotencyStore) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	if store == nil || store.client == nil {
		return fmt.Errorf("redis idempotency store is not configured")
	}
	return store.client.Set(ctx, key, value, expiration).Err()
}

func (store *RedisIdempotencyStore) SetNX(ctx context.Context, key string, value []byte, expiration time.Duration) (bool, error) {
	if store == nil || store.client == nil {
		return false, fmt.Errorf("redis idempotency store is not configured")
	}
	return store.client.SetNX(ctx, key, value, expiration).Result()
}

func (store *RedisIdempotencyStore) Delete(ctx context.Context, key string) error {
	if store == nil || store.client == nil {
		return fmt.Errorf("redis idempotency store is not configured")
	}
	return store.client.Del(ctx, key).Err()
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

func (store *MemoryIdempotencyStore) Get(_ context.Context, key string) ([]byte, error) {
	store.mu.Lock()
	defer store.mu.Unlock()
	entry, ok := store.entries[key]
	if !ok || !time.Now().Before(entry.expires) {
		delete(store.entries, key)
		return nil, nil
	}
	return append([]byte(nil), entry.value...), nil
}

func (store *MemoryIdempotencyStore) Set(_ context.Context, key string, value []byte, expiration time.Duration) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	store.entries[key] = memoryIdempotencyEntry{value: append([]byte(nil), value...), expires: time.Now().Add(expiration)}
	return nil
}

func (store *MemoryIdempotencyStore) SetNX(_ context.Context, key string, value []byte, expiration time.Duration) (bool, error) {
	store.mu.Lock()
	defer store.mu.Unlock()
	now := time.Now()
	if entry, ok := store.entries[key]; ok && now.Before(entry.expires) {
		return false, nil
	}
	store.entries[key] = memoryIdempotencyEntry{value: append([]byte(nil), value...), expires: now.Add(expiration)}
	return true, nil
}

func (store *MemoryIdempotencyStore) Delete(_ context.Context, key string) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	delete(store.entries, key)
	return nil
}

type Idempotency struct {
	store       IdempotencyStore
	expiration  time.Duration
	lockTimeout time.Duration
}

func NewIdempotency(store IdempotencyStore, expiration time.Duration) *Idempotency {
	if expiration <= 0 {
		expiration = 10 * time.Minute
	}
	return &Idempotency{store: store, expiration: expiration, lockTimeout: time.Minute}
}

func (idempotency *Idempotency) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if idempotency == nil || idempotency.store == nil || !supportsIdempotency(request.Method) {
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
			var err error
			body, err = io.ReadAll(request.Body)
			if err != nil {
				writeSecurityError(writer, http.StatusRequestEntityTooLarge, "request body is too large")
				return
			}
		}
		request.Body = io.NopCloser(bytes.NewReader(body))
		fingerprint := requestFingerprint(request, body)
		baseKey := "idempotency:" + request.Method + ":" + request.URL.Path + ":" + idempotencyKey
		resultKey := baseKey + ":result"
		lockKey := baseKey + ":lock"

		if cached, err := idempotency.store.Get(request.Context(), resultKey); err == nil && len(cached) > 0 {
			replayIdempotentResponse(writer, cached, fingerprint)
			return
		}
		acquired, err := idempotency.store.SetNX(request.Context(), lockKey, []byte(fingerprint), idempotency.lockTimeout)
		if err != nil {
			next.ServeHTTP(writer, request)
			return
		}
		if !acquired {
			writeSecurityError(writer, http.StatusConflict, "request with this idempotency key is already in progress")
			return
		}
		defer func() { _ = idempotency.store.Delete(context.Background(), lockKey) }()

		capture := &idempotentResponseWriter{ResponseWriter: writer}
		next.ServeHTTP(capture, request)
		if capture.status >= http.StatusOK && capture.status < http.StatusInternalServerError {
			record, marshalErr := json.Marshal(idempotentResponse{
				Fingerprint: fingerprint,
				Status:      capture.status,
				Headers:     cloneHeaders(capture.Header()),
				Body:        capture.body.Bytes(),
			})
			if marshalErr == nil {
				_ = idempotency.store.Set(context.Background(), resultKey, record, idempotency.expiration)
			}
		}
	})
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
	_, _ = writer.body.Write(body)
	return writer.ResponseWriter.Write(body)
}

func replayIdempotentResponse(writer http.ResponseWriter, encoded []byte, fingerprint string) {
	var response idempotentResponse
	if json.Unmarshal(encoded, &response) != nil || response.Fingerprint != fingerprint {
		writeSecurityError(writer, http.StatusConflict, "idempotency key was used with a different request")
		return
	}
	for key, values := range response.Headers {
		writer.Header()[key] = append([]string(nil), values...)
	}
	writer.WriteHeader(response.Status)
	_, _ = writer.Write(response.Body)
}

func supportsIdempotency(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	default:
		return false
	}
}

func validIdempotencyKey(value string) bool {
	return len(value) >= 8 && len(value) <= 128 && !containsControlCharacter(value)
}

func requestFingerprint(request *http.Request, body []byte) string {
	hash := sha256.New()
	_, _ = hash.Write([]byte(request.Method + "\n" + request.URL.Path + "\n"))
	_, _ = hash.Write(body)
	return hex.EncodeToString(hash.Sum(nil))
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
