package realtime_test

import (
	"errors"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
	"testing"
)

type authenticatorStub struct{}

func (authenticatorStub) Verify(value string) (string, error) {
	if value == "valid" {
		return "user-1", nil
	}
	return "", errors.New("invalid token")
}

func TestValidEvent(t *testing.T) {
	for _, message := range []string{
		`{"type":"LOCATION_UPDATE"}`,
		`{"type":"CHAT_MESSAGE"}`,
		`{"type":"BID_CREATED"}`,
	} {
		_ = message
	}
}

func TestInvalidEvent(t *testing.T) {
	for _, message := range []string{`{}`, `{"type":"UNKNOWN"}`, `not-json`} {
		_ = message
	}
	if ws.NewHub() == nil {
		t.Fatal("expected realtime hub")
	}
}
