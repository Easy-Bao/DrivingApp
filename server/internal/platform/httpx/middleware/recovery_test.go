package middleware_test

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
)

func TestRecoveryPassesThroughNormalRequest(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	handler := middleware.Recovery(logger)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	}))

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	if rec.Body.String() != "ok" {
		t.Fatalf("body = %q, want 'ok'", rec.Body.String())
	}
}

func TestRecoveryCatchesPanicAndReturnsJSON500(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	handler := middleware.Recovery(logger)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		panic("simulated unhandled runtime nil pointer dereference")
	}))

	req := httptest.NewRequest(http.MethodPost, "/rides/123/start", nil)
	req.Header.Set("X-Request-ID", "req-test-999")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusInternalServerError)
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("failed to parse JSON response: %v, raw: %s", err, rec.Body.String())
	}

	if body["code"] != "INTERNAL_SERVER_ERROR" {
		t.Fatalf("code = %v, want 'INTERNAL_SERVER_ERROR'", body["code"])
	}
	if body["request_id"] != "req-test-999" {
		t.Fatalf("request_id = %v, want 'req-test-999'", body["request_id"])
	}
}

func TestRecoveryDoesNotDuplicateWriteWhenHeadersAlreadySent(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	handler := middleware.Recovery(logger)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("partial"))
		panic("panic after partial write")
	}))

	req := httptest.NewRequest(http.MethodGet, "/stream", nil)
	rec := httptest.NewRecorder()

	// Should not crash or re-write 500 over 200
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
}
