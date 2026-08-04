package middleware

import (
	"bufio"
	"io"
	"log/slog"
	"net"
	"net/http"
	"time"
)

func Logging(logger *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			startedAt := time.Now()
			response := &statusWriter{ResponseWriter: writer}
			next.ServeHTTP(response, request)
			status := response.statusCode()
			requestID := RequestIDFromRequest(request)
			if requestID == "" {
				requestID = request.Header.Get("X-Request-ID")
			}
			logger.Info(
				"http request",
				"request_id", requestID,
				"method", request.Method,
				"path", request.URL.Path,
				"status", status,
				"client_ip", clientIP(request),
				"user_agent", request.UserAgent(),
				"duration_ms", time.Since(startedAt).Milliseconds(),
			)
			if status == http.StatusUnauthorized || status == http.StatusForbidden ||
				status == http.StatusTooManyRequests {
				logger.Warn(
					"security event",
					"event", securityEvent(status),
					"request_id", requestID,
					"method", request.Method,
					"path", request.URL.Path,
					"client_ip", clientIP(request),
					"user_agent", request.UserAgent(),
				)
			}
		})
	}
}

type statusWriter struct {
	http.ResponseWriter
	status int
}

func (writer *statusWriter) WriteHeader(status int) {
	if writer.status != 0 {
		return
	}
	writer.status = status
	writer.ResponseWriter.WriteHeader(status)
}

func (writer *statusWriter) Write(body []byte) (int, error) {
	if writer.status == 0 {
		writer.WriteHeader(http.StatusOK)
	}
	return writer.ResponseWriter.Write(body)
}

func (writer *statusWriter) Flush() {
	if writer.status == 0 {
		writer.WriteHeader(http.StatusOK)
	}
	if flusher, ok := writer.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

func (writer *statusWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	hijacker, ok := writer.ResponseWriter.(http.Hijacker)
	if !ok {
		return nil, nil, http.ErrNotSupported
	}
	return hijacker.Hijack()
}

func (writer *statusWriter) ReadFrom(reader io.Reader) (int64, error) {
	if writer.status == 0 {
		writer.WriteHeader(http.StatusOK)
	}
	if readerFrom, ok := writer.ResponseWriter.(io.ReaderFrom); ok {
		return readerFrom.ReadFrom(reader)
	}
	return io.Copy(writer.ResponseWriter, reader)
}

func (writer *statusWriter) Push(target string, options *http.PushOptions) error {
	if pusher, ok := writer.ResponseWriter.(http.Pusher); ok {
		return pusher.Push(target, options)
	}
	return http.ErrNotSupported
}

func (writer *statusWriter) Unwrap() http.ResponseWriter {
	return writer.ResponseWriter
}

func (writer *statusWriter) statusCode() int {
	if writer.status == 0 {
		return http.StatusOK
	}
	return writer.status
}

func securityEvent(status int) string {
	switch status {
	case http.StatusUnauthorized:
		return "authentication_failed"
	case http.StatusForbidden:
		return "request_forbidden"
	case http.StatusTooManyRequests:
		return "rate_limit_exceeded"
	default:
		return "request_rejected"
	}
}
