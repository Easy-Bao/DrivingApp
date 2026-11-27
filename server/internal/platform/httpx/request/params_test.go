package request

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
)

func requestWithURLParam(name, value string) *http.Request {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add(name, value)
	return req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
}

func TestPositiveIntParam(t *testing.T) {
	recorder := httptest.NewRecorder()
	id, ok := PositiveIntParam(recorder, requestWithURLParam("id", "42"), "id", "invalid ride id")
	if !ok || id != 42 {
		t.Fatalf("PositiveIntParam = (%d, %v), want (42, true)", id, ok)
	}
	if recorder.Code != http.StatusOK {
		t.Fatalf("unexpected status %d", recorder.Code)
	}

	for _, bad := range []string{"", "0", "-5", "abc", "2147483648"} {
		rec := httptest.NewRecorder()
		if gotID, gotOK := PositiveIntParam(rec, requestWithURLParam("id", bad), "id", "invalid ride id"); gotOK || gotID != 0 {
			t.Fatalf("PositiveIntParam(%q) = (%d, %v), want (0, false)", bad, gotID, gotOK)
		}
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("PositiveIntParam(%q) status = %d, want 400", bad, rec.Code)
		}
	}
}
