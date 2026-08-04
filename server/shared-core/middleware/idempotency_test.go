package middleware

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestIdempotencyReplaysSuccessfulResponse(t *testing.T) {
	var calls atomic.Int32
	handler := NewIdempotency(NewMemoryIdempotencyStore(), time.Minute).Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		calls.Add(1)
		writer.Header().Set("Content-Type", "application/json")
		writer.WriteHeader(http.StatusCreated)
		_, _ = writer.Write([]byte(`{"created":true}`))
	}))

	for index := 0; index < 2; index++ {
		request := httptest.NewRequest(http.MethodPost, "/rides", strings.NewReader(`{"fare_centavos":100}`))
		request.Header.Set("Idempotency-Key", "ride-key-1")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != http.StatusCreated {
			t.Fatalf("request %d status = %d, want %d", index+1, response.Code, http.StatusCreated)
		}
		if body, _ := io.ReadAll(response.Body); string(body) != `{"created":true}` {
			t.Fatalf("request %d body = %s", index+1, body)
		}
	}
	if calls.Load() != 1 {
		t.Fatalf("handler calls = %d, want 1", calls.Load())
	}
}

func TestIdempotencyRejectsKeyReuseWithDifferentBody(t *testing.T) {
	store := NewMemoryIdempotencyStore()
	handler := NewIdempotency(store, time.Minute).Middleware(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusCreated)
	}))

	first := httptest.NewRequest(http.MethodPost, "/rides", strings.NewReader(`{"fare_centavos":100}`))
	first.Header.Set("Idempotency-Key", "ride-key-2")
	handler.ServeHTTP(httptest.NewRecorder(), first)

	second := httptest.NewRequest(http.MethodPost, "/rides", strings.NewReader(`{"fare_centavos":200}`))
	second.Header.Set("Idempotency-Key", "ride-key-2")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, second)
	if response.Code != http.StatusConflict {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusConflict)
	}
}
