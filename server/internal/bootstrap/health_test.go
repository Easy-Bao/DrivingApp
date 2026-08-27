package bootstrap

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWriteReadinessResponse(t *testing.T) {
	tests := []struct {
		name   string
		status int
		ready  bool
		want   string
	}{
		{name: "ready", status: http.StatusOK, ready: true, want: "ready"},
		{name: "not ready", status: http.StatusServiceUnavailable, want: "not_ready"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			writer := httptest.NewRecorder()
			writeReadinessResponse(writer, test.status, test.ready)

			if writer.Code != test.status {
				t.Fatalf("status = %d, want %d", writer.Code, test.status)
			}
			var body map[string]string
			if err := json.Unmarshal(writer.Body.Bytes(), &body); err != nil {
				t.Fatalf("decode readiness response: %v", err)
			}
			if body["status"] != test.want {
				t.Fatalf("status body = %q, want %q", body["status"], test.want)
			}
			if body["service"] != serviceName {
				t.Fatalf("service body = %q, want %q", body["service"], serviceName)
			}
		})
	}
}
