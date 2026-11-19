package middleware

import (
	"bufio"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"runtime/debug"
	"strings"

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

func (responseWriter *recoveryResponseWriter) Unwrap() http.ResponseWriter {
	return responseWriter.ResponseWriter
}

func (responseWriter *recoveryResponseWriter) Flush() {
	responseWriter.wroteHeader = true
	_ = http.NewResponseController(responseWriter.ResponseWriter).Flush()
}

func (responseWriter *recoveryResponseWriter) ReadFrom(reader io.Reader) (int64, error) {
	responseWriter.wroteHeader = true
	if readerFrom, ok := responseWriter.ResponseWriter.(io.ReaderFrom); ok {
		return readerFrom.ReadFrom(reader)
	}
	return io.Copy(responseWriter.ResponseWriter, reader)
}

func (responseWriter *recoveryResponseWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	connection, buffered, err := http.NewResponseController(responseWriter.ResponseWriter).Hijack()
	if err == nil {
		responseWriter.wroteHeader = true
	}
	return connection, buffered, err
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
					if recoveredPanic == http.ErrAbortHandler {
						panic(recoveredPanic)
					}
					stack := debug.Stack()
					requestID := RequestIDFromRequest(request)
					if requestID == "" {
						requestID = responseWriter.Header().Get("X-Request-ID")
					}
					if requestID == "" {
						if candidate := strings.TrimSpace(request.Header.Get("X-Request-ID")); validRequestID(candidate) {
							requestID = candidate
						}
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
