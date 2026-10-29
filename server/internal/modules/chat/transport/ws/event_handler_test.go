package ws

import (
	"context"
	"errors"
	"testing"
	"time"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	assignment "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
)

type roomRepositoryStub struct {
	message domain.Message
}

func (*roomRepositoryStub) CreateRoom(context.Context, string, string, string) error { return nil }
func (stub *roomRepositoryStub) Append(_ context.Context, message domain.Message) error {
	stub.message = message
	return nil
}
func (*roomRepositoryStub) Messages(context.Context, string) ([]domain.Message, error) {
	return nil, nil
}
func (*roomRepositoryStub) Resolve(context.Context, string) error { return nil }
func (*roomRepositoryStub) RoomParticipants(context.Context, string) (string, string, error) {
	return "7", "8", nil
}
func (*roomRepositoryStub) IsMember(context.Context, string, string) (bool, error) {
	return true, nil
}
func (*roomRepositoryStub) IsLocked(context.Context, string) (bool, error) { return false, nil }

type assignmentLookupStub struct{}

func (assignmentLookupStub) ForDriver(context.Context, string) ([]assignment.Assignment, error) {
	return nil, nil
}

func (assignmentLookupStub) ForRide(_ context.Context, rideID string) (assignment.Assignment, bool, error) {
	return assignment.Assignment{
		RideID: rideID, PassengerID: "7", DriverID: "8", Status: "assigned",
	}, true, nil
}

func TestEventHandlerKeepsServerIdentityAndTimestamp(t *testing.T) {
	history := &roomRepositoryStub{}
	service := application.NewService(application.Dependencies{History: history}).
		WithRideAssignmentLookup(assignmentLookupStub{})
	handler := NewEventHandler(service)
	before := time.Now().UTC()

	err := handler.Handle(context.Background(), []byte(`{
		"type":"message",
		"room_id":"303",
		"sender_id":"7",
		"senderId":"attacker",
		"text":"hello",
		"created_at":"2000-01-01T00:00:00Z",
		"createdAt":"2099-01-01T00:00:00Z"
	}`))
	if err != nil {
		t.Fatal(err)
	}
	if history.message.SenderID != "7" || history.message.Body != "hello" {
		t.Fatalf("stored message = %#v", history.message)
	}
	createdAt, err := time.Parse(time.RFC3339Nano, history.message.CreatedAt)
	if err != nil || createdAt.Before(before) || createdAt.After(time.Now().UTC().Add(time.Second)) {
		t.Fatalf("server timestamp = %q, error = %v", history.message.CreatedAt, err)
	}
}

func (*roomRepositoryStub) MarkRead(context.Context, string, string, string) error { return nil }

func TestEventHandlerRejectsMalformedAndUnsupportedEvents(t *testing.T) {
	history := &roomRepositoryStub{}
	service := application.NewService(application.Dependencies{History: history}).
		WithRideAssignmentLookup(assignmentLookupStub{})
	handler := NewEventHandler(service)

	cases := []struct {
		name    string
		payload string
	}{
		{
			name:    "invalid json header",
			payload: `not-valid-json`,
		},
		{
			name:    "unsupported event type",
			payload: `{"type":"unknown_type","room_id":"303"}`,
		},
		{
			name:    "typing event missing is_typing",
			payload: `{"type":"typing","room_id":"303","sender_id":"7"}`,
		},
		{
			name:    "malformed typing payload format",
			payload: `{"type":"typing","room_id":123,"sender_id":456,"is_typing":"not-a-bool"}`,
		},
		{
			name:    "malformed message payload format",
			payload: `{"type":"message","room_id":123,"text":{}}`,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := handler.Handle(context.Background(), []byte(tc.payload))
			if err == nil {
				t.Fatalf("expected error for payload %q, got nil", tc.payload)
			}
			if !errors.Is(err, domain.ErrInvalidMessage) {
				t.Fatalf("expected error wrapping domain.ErrInvalidMessage, got %v", err)
			}
		})
	}
}
