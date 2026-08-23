package middleware

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/shared-core/response"
)

const (
	defaultJSONBodyLimit   int64 = 16 << 10
	defaultUploadBodyLimit int64 = 10 << 20
)

type SecurityConfig struct {
	AllowedOrigins  []string
	EnableHSTS      bool
	JSONBodyLimit   int64
	UploadBodyLimit int64
}

func SecurityConfigFromEnv() SecurityConfig {
	return SecurityConfig{
		AllowedOrigins:  parseOrigins(os.Getenv("CORS_ALLOWED_ORIGINS")),
		EnableHSTS:      strings.EqualFold(strings.TrimSpace(os.Getenv("ENABLE_HSTS")), "true"),
		JSONBodyLimit:   positiveInt64Env("JSON_BODY_LIMIT_BYTES", defaultJSONBodyLimit),
		UploadBodyLimit: positiveInt64Env("UPLOAD_BODY_LIMIT_BYTES", defaultUploadBodyLimit),
	}
}

func SecureHTTP(next http.Handler, config SecurityConfig, limiter *RateLimiter) http.Handler {
	return SecureHTTPWithIdempotency(next, config, limiter, nil)
}

func SecureHTTPWithIdempotency(next http.Handler, config SecurityConfig, limiter *RateLimiter, idempotency *Idempotency) http.Handler {
	if config.JSONBodyLimit <= 0 {
		config.JSONBodyLimit = defaultJSONBodyLimit
	}
	if config.UploadBodyLimit <= 0 {
		config.UploadBodyLimit = defaultUploadBodyLimit
	}

	handler := next
	if limiter != nil {
		handler = limiter.Middleware(handler)
	}
	if idempotency != nil {
		handler = idempotency.Middleware(handler)
	}
	handler = RequestBodyLimit(config.JSONBodyLimit, config.UploadBodyLimit)(handler)
	handler = RejectControlCharacters(handler)
	handler = CORS(config.AllowedOrigins)(handler)
	handler = SecurityHeaders(config.EnableHSTS)(handler)
	return RequestID(handler)
}

func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		requestID := strings.TrimSpace(request.Header.Get("X-Request-ID"))
		if !validRequestID(requestID) {
			requestID = newRequestID()
		}
		writer.Header().Set("X-Request-ID", requestID)
		next.ServeHTTP(writer, request.WithContext(withRequestID(request.Context(), requestID)))
	})
}

func RequestIDFromRequest(request *http.Request) string {
	requestID, _ := request.Context().Value(requestIDKey{}).(string)
	return requestID
}

func RequestBodyLimit(jsonLimit, uploadLimit int64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			if request.Body == nil || request.Body == http.NoBody {
				next.ServeHTTP(writer, request)
				return
			}

			limit := jsonLimit
			contentType := strings.ToLower(request.Header.Get("Content-Type"))
			if strings.HasPrefix(contentType, "multipart/") || strings.Contains(request.URL.Path, "/documents") {
				limit = uploadLimit
			}
			if request.ContentLength > limit {
				writeSecurityError(writer, http.StatusRequestEntityTooLarge, "request body is too large")
				return
			}
			request.Body = http.MaxBytesReader(writer, request.Body, limit)
			next.ServeHTTP(writer, request)
		})
	}
}

func RejectControlCharacters(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if containsControlCharacter(request.URL.Path) || containsControlCharacter(request.URL.RawQuery) {
			writeSecurityError(writer, http.StatusBadRequest, "invalid request target")
			return
		}
		next.ServeHTTP(writer, request)
	})
}

func SecurityHeaders(enableHSTS bool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			writer.Header().Set("X-Content-Type-Options", "nosniff")
			writer.Header().Set("X-Frame-Options", "DENY")
			writer.Header().Set("Referrer-Policy", "no-referrer")
			writer.Header().Set("Permissions-Policy", "camera=(), geolocation=(), microphone=()")
			writer.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; base-uri 'none'")
			if enableHSTS || RequestSchemeFromRequest(request) == "https" {
				writer.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
			}
			next.ServeHTTP(writer, request)
		})
	}
}

func CORS(allowedOrigins []string) func(http.Handler) http.Handler {
	allowed := make(map[string]struct{}, len(allowedOrigins))
	for _, origin := range allowedOrigins {
		allowed[strings.TrimSpace(origin)] = struct{}{}
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			origin := strings.TrimSpace(request.Header.Get("Origin"))
			if origin != "" {
				if _, ok := allowed[origin]; !ok {
					writeSecurityError(writer, http.StatusForbidden, "origin is not allowed")
					return
				}
				writer.Header().Set("Access-Control-Allow-Origin", origin)
				writer.Header().Set("Vary", "Origin")
				writer.Header().Set("Access-Control-Allow-Credentials", "true")
				writer.Header().Set("Access-Control-Expose-Headers", "X-Request-ID, Retry-After")
			}
			if request.Method == http.MethodOptions {
				if origin == "" {
					writeSecurityError(writer, http.StatusForbidden, "origin is required")
					return
				}
				writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
				writer.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, Idempotency-Key, X-Request-ID")
				writer.WriteHeader(http.StatusNoContent)
				return
			}
			next.ServeHTTP(writer, request)
		})
	}
}

func parseOrigins(raw string) []string {
	values := strings.Split(raw, ",")
	origins := make([]string, 0, len(values))
	for _, value := range values {
		if origin := strings.TrimSpace(value); origin != "" {
			origins = append(origins, origin)
		}
	}
	return origins
}

func positiveInt64Env(key string, fallback int64) int64 {
	value, err := strconv.ParseInt(strings.TrimSpace(os.Getenv(key)), 10, 64)
	if err != nil || value <= 0 {
		return fallback
	}
	return value
}

func validRequestID(value string) bool {
	if len(value) < 8 || len(value) > 128 {
		return false
	}
	return !containsControlCharacter(value)
}

func newRequestID() string {
	var bytes [16]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return "request-unknown"
	}
	return hex.EncodeToString(bytes[:])
}

func containsControlCharacter(value string) bool {
	for _, character := range value {
		if character < 0x20 || character == 0x7f {
			return true
		}
	}
	return false
}

func writeSecurityError(writer http.ResponseWriter, status int, message string) {
	response.Error(writer, status, message)
}

type requestIDKey struct{}

func withRequestID(contextValue context.Context, requestID string) context.Context {
	return context.WithValue(contextValue, requestIDKey{}, requestID)
}
