package middleware

import (
	"fmt"
	"log/slog"
	"net/http"
	"runtime/debug"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/response"
)

type recoveryResponseWriter struct {
	http.ResponseWriter
	wroteHeader bool
}

func (rw *recoveryResponseWriter) WriteHeader(code int) {
	rw.wroteHeader = true
	rw.ResponseWriter.WriteHeader(code)
}

func (rw *recoveryResponseWriter) Write(b []byte) (int, error) {
	rw.wroteHeader = true
	return rw.ResponseWriter.Write(b)
}

// Recovery catches unhandled panics in downstream HTTP handlers, logs the stack trace
// with request correlation metadata, and returns a structured HTTP 500 JSON envelope.
func Recovery(logger *slog.Logger) func(http.Handler) http.Handler {
	if logger == nil {
		logger = slog.Default()
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			rw := &recoveryResponseWriter{ResponseWriter: w}
			defer func() {
				if rec := recover(); rec != nil {
					stack := debug.Stack()
					reqID := RequestIDFromRequest(r)
					if reqID == "" {
						reqID = r.Header.Get("X-Request-ID")
					}
					if reqID == "" {
						reqID = rw.Header().Get("X-Request-ID")
					}

					logger.ErrorContext(r.Context(), "unhandled http panic recovered",
						"error", fmt.Sprintf("%v", rec),
						"request_id", reqID,
						"path", r.URL.Path,
						"method", r.Method,
						"stack", string(stack),
					)

					if !rw.wroteHeader {
						rw.Header().Set("Connection", "close")
						response.JSON(rw, http.StatusInternalServerError, map[string]any{
							"code":       "INTERNAL_SERVER_ERROR",
							"message":    "An unexpected error occurred.",
							"request_id": reqID,
						})
					}
				}
			}()
			next.ServeHTTP(rw, r)
		})
	}
}
