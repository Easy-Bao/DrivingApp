package response

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
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
