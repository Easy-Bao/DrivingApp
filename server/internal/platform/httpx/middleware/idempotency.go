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
	"time"
)

type Idempotency struct {
	store       IdempotencyStore
	expiration  time.Duration
	lockTimeout time.Duration
	logger      *slog.Logger
}

const _maxIdempotencyBodyBytes int64 = 10 << 20

const _defaultIdempotencyExpiration = 10 * time.Minute

type IdempotencyOption func(*Idempotency)

type IdempotencyDependencies struct {
	Store IdempotencyStore
}

func WithIdempotencyExpiration(expiration time.Duration) IdempotencyOption {
	return func(idempotency *Idempotency) {
		if expiration > 0 {
			idempotency.expiration = expiration
		}
	}
}

func NewIdempotency(
	dependencies IdempotencyDependencies,
	options ...IdempotencyOption,
) *Idempotency {
	idempotency := &Idempotency{
		store:       dependencies.Store,
		expiration:  _defaultIdempotencyExpiration,
		lockTimeout: time.Minute,
		logger:      slog.Default(),
	}
	for _, option := range options {
		if option != nil {
			option(idempotency)
		}
	}
	return idempotency
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
		if idempotency.store == nil || !isStateChangingMethod(request.Method) {
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
			request.Body = http.MaxBytesReader(writer, request.Body, _maxIdempotencyBodyBytes)
			var err error
			body, err = io.ReadAll(request.Body)
			if err != nil {
				var maxBytesErr *http.MaxBytesError
				if errors.As(err, &maxBytesErr) {
					writeSecurityError(writer, http.StatusRequestEntityTooLarge, "request body is too large")
					return
				}
				writeSecurityError(writer, http.StatusBadRequest, "failed to read request body")
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
			writeProtectionUnavailable(writer)
			return
		}
		if len(cached) > 0 {
			replayIdempotentResponse(writer, cached, fingerprint)
			return
		}
		lockToken, err := newLockToken()
		if err != nil {
			writeProtectionUnavailable(writer)
			return
		}
		acquired, err := idempotency.store.SetNX(
			request.Context(),
			lockKey,
			lockToken,
			idempotency.lockTimeout,
		)
		if err != nil {
			writeProtectionUnavailable(writer)
			return
		}
		if !acquired {
			writeSecurityError(writer, http.StatusConflict, "request with this idempotency key is already in progress")
			return
		}
		defer idempotency.releaseLock(request, lockKey, lockToken)

		// A concurrent request may have stored its result and released the lock
		// between the first lookup and this acquisition; replay it instead of
		// running the command a second time.
		cached, err = idempotency.store.Get(request.Context(), resultKey)
		if err != nil {
			writeProtectionUnavailable(writer)
			return
		}
		if len(cached) > 0 {
			replayIdempotentResponse(writer, cached, fingerprint)
			return
		}

		capture := &idempotentResponseWriter{ResponseWriter: writer}
		next.ServeHTTP(capture, request)
		if !capture.uncacheable && capture.status >= http.StatusOK && capture.status < http.StatusMultipleChoices {
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
	if request == nil {
		return
	}
	ctx := request.Context()
	if ctx == nil {
		ctx = context.Background()
	}
	cleanupContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), time.Second)
	defer cancel()
	if err := idempotency.store.DeleteIfValue(cleanupContext, key, token); err != nil {
		idempotency.log().WarnContext(
			ctx,
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

type idempotentResponse struct {
	Fingerprint string              `json:"fingerprint"`
	Status      int                 `json:"status"`
	Headers     map[string][]string `json:"headers"`
	Body        []byte              `json:"body"`
}

type idempotentResponseWriter struct {
	http.ResponseWriter
	body        bytes.Buffer
	status      int
	uncacheable bool
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
	if !writer.uncacheable {
		if int64(writer.body.Len()+len(body)) > _maxIdempotencyBodyBytes {
			writer.uncacheable = true
			writer.body = bytes.Buffer{}
		} else {
			if _, err := writer.body.Write(body); err != nil {
				slog.Error("capture idempotent response body failed", "error", err)
			}
		}
	}
	return writer.ResponseWriter.Write(body)
}

func (writer *idempotentResponseWriter) Unwrap() http.ResponseWriter {
	return writer.ResponseWriter
}

func (writer *idempotentResponseWriter) Flush() {
	if flusher, ok := writer.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
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
	if len(response.Body) > 0 {
		if _, err := writer.Write(response.Body); err != nil {
			slog.Debug("replay idempotent response failed", "error", err)
		}
	}
}

func authorizationScope(request *http.Request) string {
	if principal, ok := PrincipalFromRequest(request); ok {
		hash := sha256.Sum256([]byte(fmt.Sprintf("%s:%d", principal.Role, principal.UserID)))
		return hex.EncodeToString(hash[:])
	}
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
		if !isCacheableRepresentationHeader(key) {
			continue
		}
		clone[key] = append([]string(nil), values...)
	}
	return clone
}

func isCacheableRepresentationHeader(key string) bool {
	switch http.CanonicalHeaderKey(key) {
	case "Content-Type",
		"Content-Language",
		"Content-Disposition",
		"Content-Encoding",
		"Location",
		"Etag",
		"Last-Modified",
		"Cache-Control",
		"Deprecation",
		"Sunset",
		"Link":
		return true
	default:
		return false
	}
}
