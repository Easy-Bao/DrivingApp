package middleware

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestLoggingUsesGeneratedResponseRequestID(t *testing.T) {
	var output bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&output, nil))
	handler := Logging(logger)(RequestID(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	})))
	handler.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/health", nil))

	var entry map[string]any
	if err := json.Unmarshal(output.Bytes(), &entry); err != nil {
		t.Fatal(err)
	}
	if entry["request_id"] == nil || entry["request_id"] == "" {
		t.Fatal("generated request ID was not included in the request log")
	}
}

func TestLoggingRecordsPayloadSizesAndCancellationWithoutBodies(t *testing.T) {
	const requestBody = "request-payload"
	const responseBody = "opaque-value-zq7"
	var output bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&output, nil))
	request := httptest.NewRequest(http.MethodPost, "/upload", strings.NewReader(requestBody))
	ctx, cancel := context.WithCancel(request.Context())
	defer cancel()
	request = request.WithContext(ctx)
	handler := Logging(logger)(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		cancel()
		_, _ = writer.Write([]byte(responseBody))
	}))
	handler.ServeHTTP(httptest.NewRecorder(), request)

	var entry map[string]any
	if err := json.Unmarshal(output.Bytes(), &entry); err != nil {
		t.Fatal(err)
	}
	if entry["request_bytes"] != float64(len(requestBody)) {
		t.Fatalf("request_bytes = %v, want %d", entry["request_bytes"], len(requestBody))
	}
	if entry["response_bytes"] != float64(len(responseBody)) {
		t.Fatalf("response_bytes = %v, want %d", entry["response_bytes"], len(responseBody))
	}
	if entry["cancelled"] != true {
		t.Fatalf("cancelled = %v, want true", entry["cancelled"])
	}
	if strings.Contains(output.String(), requestBody) || strings.Contains(output.String(), responseBody) {
		t.Fatal("request or response body was included in the request log")
	}
}
