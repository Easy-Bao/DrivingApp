package http

import (
	"errors"
	"net/http"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
)

func TestChatErrorStatusMapsDomainFailures(t *testing.T) {
	tests := []struct {
		name string
		err  error
		want int
	}{
		{name: "invalid room", err: domain.ErrInvalidRoom, want: http.StatusBadRequest},
		{name: "wrapped conflict", err: errors.Join(errors.New("storage"), domain.ErrRoomConflict), want: http.StatusConflict},
		{name: "locked room", err: domain.ErrRoomLocked, want: http.StatusLocked},
		{name: "forbidden", err: domain.ErrForbidden, want: http.StatusForbidden},
		{name: "unavailable", err: domain.ErrRoomUnavailable, want: http.StatusServiceUnavailable},
		{name: "unknown", err: errors.New("unexpected"), want: http.StatusInternalServerError},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := chatErrorStatus(test.err); got != test.want {
				t.Fatalf("chatErrorStatus() = %d, want %d", got, test.want)
			}
		})
	}
}
