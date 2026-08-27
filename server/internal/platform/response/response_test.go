package response

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestErrorUsesProblemContractAndKeepsLegacyMessageFields(t *testing.T) {
	writer := httptest.NewRecorder()

	Error(writer, http.StatusForbidden, "ride access denied")

	if writer.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want %d", writer.Code, http.StatusForbidden)
	}
	if contentType := writer.Header().Get("Content-Type"); contentType != "application/problem+json" {
		t.Fatalf("content type = %q", contentType)
	}
	var problem Problem
	if err := json.Unmarshal(writer.Body.Bytes(), &problem); err != nil {
		t.Fatalf("decode problem: %v", err)
	}
	if problem.Status != http.StatusForbidden || problem.Code != "forbidden" || problem.Error != "ride access denied" || problem.Message != "ride access denied" {
		t.Fatalf("problem = %#v", problem)
	}
}

func TestJSONWritesJSONContentTypeBeforeStatus(t *testing.T) {
	writer := httptest.NewRecorder()

	JSON(writer, http.StatusOK, map[string]string{"status": "ok"})

	if writer.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", writer.Code, http.StatusOK)
	}
	if contentType := writer.Header().Get("Content-Type"); contentType != "application/json; charset=utf-8" {
		t.Fatalf("content type = %q", contentType)
	}
	var payload map[string]string
	if err := json.Unmarshal(writer.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode payload: %v", err)
	}
	if payload["status"] != "ok" {
		t.Fatalf("payload = %#v", payload)
	}
}

func TestJSONUsesSafeProblemWhenPayloadCannotBeEncoded(t *testing.T) {
	writer := httptest.NewRecorder()
	JSON(writer, http.StatusOK, struct{ Callback func() }{})

	if writer.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", writer.Code, http.StatusInternalServerError)
	}
	if contentType := writer.Header().Get("Content-Type"); contentType != "application/problem+json" {
		t.Fatalf("content type = %q", contentType)
	}
	if strings.Contains(writer.Body.String(), "unsupported type") {
		t.Fatalf("technical serialization detail leaked: %s", writer.Body.String())
	}
	var problem Problem
	if err := json.Unmarshal(writer.Body.Bytes(), &problem); err != nil {
		t.Fatalf("decode problem: %v", err)
	}
	if problem.Title != "Something went wrong on our end" || problem.Status != http.StatusInternalServerError {
		t.Fatalf("problem = %#v", problem)
	}
}
