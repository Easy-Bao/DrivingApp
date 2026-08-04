package ws

import (
	"errors"
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
		if !validEvent([]byte(message)) {
			t.Errorf("expected event to be valid: %s", message)
		}
	}
}

func TestInvalidEvent(t *testing.T) {
	for _, message := range []string{`{}`, `{"type":"UNKNOWN"}`, `not-json`} {
		if validEvent([]byte(message)) {
			t.Errorf("expected event to be invalid: %s", message)
		}
	}
}
