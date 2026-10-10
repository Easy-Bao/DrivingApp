package middleware

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/response"
)

const (
	_defaultJSONBodyLimit   int64 = 16 << 10
	_defaultUploadBodyLimit int64 = 10 << 20
	_multipartEnvelopeLimit int64 = 64 << 10
	_maxInt64               int64 = 1<<63 - 1
)

type SecurityConfig struct {
	AllowedOrigins  []string
	EnableHSTS      bool
	JSONBodyLimit   int64
	UploadBodyLimit int64
}

type HSTSMode uint8

const (
	HSTSDisabled HSTSMode = iota + 1
	HSTSEnabled
)

func DefaultSecurityConfig() SecurityConfig {
	return SecurityConfig{
		JSONBodyLimit:   _defaultJSONBodyLimit,
		UploadBodyLimit: _defaultUploadBodyLimit,
	}
}

func SecureHTTP(next http.Handler, config SecurityConfig) http.Handler {
	handler := next
	handler = RejectControlCharacters(handler)
	handler = CORS(config.AllowedOrigins)(handler)
	hstsMode := HSTSDisabled
	if config.EnableHSTS {
		hstsMode = HSTSEnabled
	}
	handler = SecurityHeaders(hstsMode)(handler)
	return RequestID(handler)
}

func normalizedSecurityConfig(config SecurityConfig) SecurityConfig {
	defaults := DefaultSecurityConfig()
	if config.JSONBodyLimit <= 0 {
		config.JSONBodyLimit = defaults.JSONBodyLimit
	}
	if config.UploadBodyLimit <= 0 {
		config.UploadBodyLimit = defaults.UploadBodyLimit
	}

	return config
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
	if request == nil {
		return ""
	}
	requestID, ok := request.Context().Value(requestIDKey{}).(string)
	if !ok {
		return ""
	}
	return requestID
}

func RequestBodyLimit(jsonLimit, uploadLimit int64) func(http.Handler) http.Handler {
	return requestBodyLimit(jsonLimit, uploadLimit, false)
}

func DocumentUploadBodyLimit(jsonLimit, uploadLimit int64) func(http.Handler) http.Handler {
	return requestBodyLimit(jsonLimit, uploadLimit, true)
}

func requestBodyLimit(jsonLimit, uploadLimit int64, documentUpload bool) func(http.Handler) http.Handler {
	config := normalizedSecurityConfig(SecurityConfig{
		JSONBodyLimit:   jsonLimit,
		UploadBodyLimit: uploadLimit,
	})
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			if request.Body == nil || request.Body == http.NoBody {
				next.ServeHTTP(writer, request)
				return
			}

			limit := config.JSONBodyLimit
			contentType := strings.ToLower(request.Header.Get("Content-Type"))
			if strings.HasPrefix(contentType, "multipart/") {
				limit = config.UploadBodyLimit
				if documentUpload && limit <= _maxInt64-_multipartEnvelopeLimit {
					limit += _multipartEnvelopeLimit
				}
			} else if documentUpload {
				limit = config.UploadBodyLimit
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

func SecurityHeaders(mode HSTSMode) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			writer.Header().Set("X-Content-Type-Options", "nosniff")
			writer.Header().Set("X-Frame-Options", "DENY")
			writer.Header().Set("Referrer-Policy", "no-referrer")
			writer.Header().Set("Permissions-Policy", "camera=(), geolocation=(), microphone=()")
			writer.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; base-uri 'none'")
			enableHSTS := mode == HSTSEnabled
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

func validRequestID(value string) bool {
	if len(value) < 8 || len(value) > 128 {
		return false
	}
	return !containsControlCharacter(value)
}

func newRequestID() string {
	var bytes [16]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return "request-" + strconv.FormatInt(time.Now().UnixNano(), 10)
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
