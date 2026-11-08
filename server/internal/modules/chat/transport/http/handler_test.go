package http

import (
	"bytes"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
)

func TestChatHandlerRejectsBlankInputsAndUnavailableService(t *testing.T) {
	verifier := security.NewTokenManager("0123456789abcdef0123456789abcdef")
	token, err := verifier.IssueWithRole("7", "passenger")
	if err != nil {
		t.Fatal(err)
	}
	unavailableHandler := NewHandler(Dependencies{Verifier: verifier})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/chat/rooms", bytes.NewBufferString(`{"ride_id":"ride-1"}`))
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	unavailableHandler.CreateRoom(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusServiceUnavailable)
	}
}

func TestChatErrorStatusMapsDomainFailures(t *testing.T) {
	tests := []struct {
		name string
		err  error
		want int
	}{
		{name: "invalid room", err: domain.ErrInvalidRoom, want: http.StatusBadRequest},
		{
			name: "wrapped conflict",
			err:  errors.Join(errors.New("storage"), domain.ErrRoomConflict),
			want: http.StatusConflict,
		},
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
