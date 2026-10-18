package app

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNotFoundHandlerReturnsProblemJSON(t *testing.T) {
	handler := notFoundHandler(nil)
	req := httptest.NewRequest(http.MethodGet, "/non-existent", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusNotFound)
	}

	if ct := rec.Header().Get("Content-Type"); ct != "application/problem+json" {
		t.Fatalf("Content-Type = %q, want 'application/problem+json'", ct)
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal problem json: %v", err)
	}

	if body["code"] != "not_found" {
		t.Fatalf("code = %v, want 'not_found'", body["code"])
	}
	if body["message"] != "Resource not found." {
		t.Fatalf("message = %v, want 'Resource not found.'", body["message"])
	}
}

func TestMethodNotAllowedHandlerReturnsProblemJSON(t *testing.T) {
	handler := methodNotAllowedHandler(nil)
	req := httptest.NewRequest(http.MethodPost, "/read-only", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
	}

	if ct := rec.Header().Get("Content-Type"); ct != "application/problem+json" {
		t.Fatalf("Content-Type = %q, want 'application/problem+json'", ct)
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal problem json: %v", err)
	}

	if body["code"] != "method_not_allowed" {
		t.Fatalf("code = %v, want 'method_not_allowed'", body["code"])
	}
	if body["message"] != "Method not allowed." {
		t.Fatalf("message = %v, want 'Method not allowed.'", body["message"])
	}
}
