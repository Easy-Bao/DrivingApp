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

func (responseWriter *recoveryResponseWriter) WriteHeader(code int) {
	responseWriter.wroteHeader = true
	responseWriter.ResponseWriter.WriteHeader(code)
}

func (responseWriter *recoveryResponseWriter) Write(payload []byte) (int, error) {
	responseWriter.wroteHeader = true
	return responseWriter.ResponseWriter.Write(payload)
}

// Recovery catches unhandled panics in downstream HTTP handlers, logs the stack trace
// with request correlation metadata, and returns a structured HTTP 500 JSON envelope.
func Recovery(logger *slog.Logger) func(http.Handler) http.Handler {
	if logger == nil {
		logger = slog.Default()
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			responseWriter := &recoveryResponseWriter{ResponseWriter: writer}
			defer func() {
				if recoveredPanic := recover(); recoveredPanic != nil {
					stack := debug.Stack()
					requestID := RequestIDFromRequest(request)
					if requestID == "" {
						requestID = request.Header.Get("X-Request-ID")
					}
					if requestID == "" {
						requestID = responseWriter.Header().Get("X-Request-ID")
					}

					logger.ErrorContext(request.Context(), "unhandled http panic recovered",
						"error", fmt.Sprintf("%v", recoveredPanic),
						"request_id", requestID,
						"path", request.URL.Path,
						"method", request.Method,
						"stack", string(stack),
					)

					if !responseWriter.wroteHeader {
						responseWriter.Header().Set("Connection", "close")
						response.WriteProblem(responseWriter, response.Problem{
							Status:    http.StatusInternalServerError,
							Code:      "internal_error",
							Message:   "An unexpected error occurred.",
							RequestID: requestID,
						})
					}
				}
			}()
			next.ServeHTTP(responseWriter, request)
		})
	}
}
