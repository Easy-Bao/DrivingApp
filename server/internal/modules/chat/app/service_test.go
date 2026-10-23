package app_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"image"
	"image/png"
	"testing"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/domain"
	assignment "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

type chatHistory struct {
	messages    []domain.Message
	passengerID string
	driverID    string
	locked      bool
}

func newChatService(history application.RoomStore) *application.Service {
	return application.NewService(application.Dependencies{History: history}).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID: "ride-1", PassengerID: "7", DriverID: "8", Status: "assigned",
			},
			found: true,
		})
}

type chatAssignmentLookup struct {
	assignment assignment.Assignment
	found      bool
}

func (lookup chatAssignmentLookup) ForDriver(context.Context, string) ([]assignment.Assignment, error) {
	if !lookup.found {
		return nil, nil
	}
	return []assignment.Assignment{lookup.assignment}, nil
}

func (lookup chatAssignmentLookup) ForRide(context.Context, string) (assignment.Assignment, bool, error) {
	return lookup.assignment, lookup.found, nil
}

func (history *chatHistory) CreateRoom(
	_ context.Context,
	_ string,
	passengerID string,
	driverID string,
) error {
	history.passengerID = passengerID
	history.driverID = driverID
	return nil
}
func (history *chatHistory) Append(_ context.Context, message domain.Message) error {
	history.messages = append(history.messages, message)
	return nil
}
func (history *chatHistory) Messages(context.Context, string) ([]domain.Message, error) {
	return history.messages, nil
}
func (history *chatHistory) Resolve(context.Context, string) error { return nil }
func (history *chatHistory) RoomParticipants(context.Context, string) (string, string, error) {
	return history.passengerID, history.driverID, nil
}
func (history *chatHistory) IsMember(context.Context, string, string) (bool, error) {
	return true, nil
}
func (history *chatHistory) IsLocked(context.Context, string) (bool, error) {
	return history.locked, nil
}

func TestChatCreateRoomDoesNotReplaceParticipants(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID: "ride-1", PassengerID: "passenger-1", DriverID: "driver-1", Status: "assigned",
			},
			found: true,
		})

	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"passenger-2",
	); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("create room error = %v, want %v", err, domain.ErrForbidden)
	}
	if history.passengerID != "passenger-1" || history.driverID != "driver-1" {
		t.Fatalf("room participants changed to %q/%q", history.passengerID, history.driverID)
	}
}

func TestChatCreateRoomRequiresTheAssignedRideParticipants(t *testing.T) {
	history := &chatHistory{}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
				Status:      "assigned",
				ContactOpen: true,
			},
			found: true,
		})

	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"driver-2",
	); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("create room error = %v, want %v", err, domain.ErrForbidden)
	}
	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"passenger-1",
	); err != nil {
		t.Fatalf("assigned participants could not create room: %v", err)
	}
}

func TestChatCreateRoomUsesAuthoritativeParticipants(t *testing.T) {
	history := &chatHistory{}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
				Status:      "completed",
				ContactOpen: true,
			},
			found: true,
		})

	if err := service.OpenRideRoom(
		context.Background(),
		"ride-1",
		"driver-1",
	); err != nil {
		t.Fatalf("authoritative participant could not create room: %v", err)
	}
	if history.passengerID != "passenger-1" || history.driverID != "driver-1" {
		t.Fatalf("created room participants = %q/%q", history.passengerID, history.driverID)
	}
}

func TestChatRelayRejectsResolvedRoom(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1", locked: true}
	service := newChatService(history)

	err := service.Relay(context.Background(), domain.Message{
		RoomID:   "ride-1",
		SenderID: "8",
		Body:     "This message must not be stored.",
	})
	if !errors.Is(err, domain.ErrRoomLocked) {
		t.Fatalf("relay error = %v, want %v", err, domain.ErrRoomLocked)
	}
	if len(history.messages) != 0 {
		t.Fatalf("resolved room stored %d messages", len(history.messages))
	}
}

type chatEventPublisher struct {
	events []event.Envelope
}

func (publisher *chatEventPublisher) Publish(_ context.Context, envelope event.Envelope) error {
	publisher.events = append(publisher.events, envelope)
	return nil
}

func TestChatRelayPersistsBeforeBroadcasting(t *testing.T) {
	history := &chatHistory{}
	service := newChatService(history)

	err := service.Relay(
		context.Background(),
		domain.Message{RoomID: "ride-1", SenderID: "7", Body: "hello"},
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(history.messages) != 1 || history.messages[0].Body != "hello" {
		t.Fatalf("persisted messages = %#v", history.messages)
	}
}

func TestChatRelayPublishesPassengerScopedNotification(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	events := &chatEventPublisher{}
	service := newChatService(history).
		WithEventPublisher(events).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID: "ride-1", PassengerID: "passenger-1", DriverID: "driver-1", Status: "assigned",
			},
			found: true,
		})

	if err := service.Relay(context.Background(), domain.Message{
		RoomID:    "ride-1",
		SenderID:  "driver-1",
		Body:      "I am at the pickup point.",
		CreatedAt: "2026-08-20T08:00:00Z",
	}); err != nil {
		t.Fatal(err)
	}
	if len(events.events) != 1 {
		t.Fatalf("published events = %d, want 1", len(events.events))
	}
	envelope := events.events[0]
	if envelope.Type != event.ChatMessageCreated || envelope.Scope.PassengerID != "passenger-1" {
		t.Fatalf("event routing = %#v, want chat notification for passenger-1", envelope)
	}
	var payload map[string]string
	if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
		t.Fatal(err)
	}
	if payload["sender_id"] != "driver-1" || payload["text"] != "I am at the pickup point." {
		t.Fatalf("event payload = %#v", payload)
	}
}

func TestChatRelayRejectsMessagesAfterTheRideContactWindowCloses(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID: "ride-1", PassengerID: "passenger-1", DriverID: "driver-1", Status: "completed",
			},
			found: true,
		})

	err := service.Relay(context.Background(), domain.Message{
		RoomID:   "ride-1",
		SenderID: "driver-1",
		Body:     "This message is outside the contact window.",
	})
	if !errors.Is(err, domain.ErrRoomLocked) {
		t.Fatalf("relay error = %v, want %v", err, domain.ErrRoomLocked)
	}
	if len(history.messages) != 0 {
		t.Fatalf("closed room stored %d messages", len(history.messages))
	}
}

func TestChatTypingPublishesAnAuthorizedRoomEvent(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	publisher := &chatEventPublisher{}
	service := newChatService(history).
		WithEventPublisher(publisher).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
				Status:      "assigned",
				ContactOpen: true,
			},
			found: true,
		})

	if err := service.PublishTyping(context.Background(), "ride-1", "driver-1", true); err != nil {
		t.Fatalf("PublishTyping() error = %v", err)
	}
	if len(publisher.events) != 1 {
		t.Fatalf("published events = %d, want 1", len(publisher.events))
	}
	envelope := publisher.events[0]
	if envelope.Type != event.ChatTypingChanged || envelope.Scope != (event.Scope{RoomID: "ride-1"}) {
		t.Fatalf("typing event route = %#v", envelope)
	}
	var payload map[string]any
	if err := json.Unmarshal(envelope.Payload, &payload); err != nil {
		t.Fatalf("decode typing payload: %v", err)
	}
	if payload["sender_id"] != "driver-1" || payload["is_typing"] != true {
		t.Fatalf("typing payload = %#v", payload)
	}
}

func TestChatTypingRejectsAnUnassignedSender(t *testing.T) {
	history := &chatHistory{passengerID: "passenger-1", driverID: "driver-1"}
	service := newChatService(history).
		WithRideAssignmentLookup(chatAssignmentLookup{
			assignment: assignment.Assignment{
				RideID:      "ride-1",
				PassengerID: "passenger-1",
				DriverID:    "driver-1",
				Status:      "assigned",
				ContactOpen: true,
			},
			found: true,
		})

	err := service.PublishTyping(context.Background(), "ride-1", "other-user", true)
	if !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("PublishTyping() error = %v, want %v", err, domain.ErrForbidden)
	}
}

func TestChatMessagesReturnsACopy(t *testing.T) {
	history := &chatHistory{messages: []domain.Message{{RoomID: "ride-1", Body: "original"}}}
	service := newChatService(history)

	messages, err := service.Messages(context.Background(), "ride-1")
	if err != nil {
		t.Fatalf("Messages() error = %v", err)
	}
	messages[0].Body = "mutated"
	if history.messages[0].Body != "original" {
		t.Fatalf("history was mutated through returned messages: %#v", history.messages)
	}
}

func (*chatHistory) MarkRead(context.Context, string, string, string) error { return nil }

func TestClosedConversationRetainsParticipantHistory(t *testing.T) {
	history := &chatHistory{passengerID: "7", driverID: "8", locked: true, messages: []domain.Message{{ID: "old", Body: "previous conversation"}}}
	service := newChatService(history).WithRideAssignmentLookup(chatAssignmentLookup{assignment: assignment.Assignment{RideID: "ride-1", PassengerID: "7", DriverID: "8", Status: "completed"}, found: true})
	for _, userID := range []string{"7", "8"} {
		messages, err := service.MessagesForUser(context.Background(), "ride-1", userID)
		if err != nil || len(messages) != 1 || messages[0].ID != "old" {
			t.Fatalf("history for %s = %v, %v", userID, messages, err)
		}
		err = service.Relay(context.Background(), domain.Message{RoomID: "ride-1", SenderID: userID, Body: "new"})
		if !errors.Is(err, domain.ErrRoomLocked) {
			t.Fatalf("closed room accepted send: %v", err)
		}
	}
	if _, err := service.MessagesForUser(context.Background(), "ride-1", "outsider"); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("outsider history: %v", err)
	}
}

func TestReadReceiptRequiresAPeerMessageAndPublishesItsTimestamp(t *testing.T) {
	history := &chatHistory{passengerID: "7", driverID: "8", messages: []domain.Message{{ID: "peer", SenderID: "8", CreatedAt: "2026-10-23T02:00:00.123456789Z"}, {ID: "own", SenderID: "7", CreatedAt: "2026-10-23T02:01:00Z"}}}
	publisher := &chatEventPublisher{}
	service := newChatService(history).WithEventPublisher(publisher)
	for _, id := range []string{"missing", "own"} {
		if err := service.MarkRead(context.Background(), "ride-1", "7", id); !errors.Is(err, domain.ErrInvalidMessage) {
			t.Fatalf("invalid receipt %s: %v", id, err)
		}
	}
	if err := service.MarkRead(context.Background(), "ride-1", "outsider", "peer"); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("outsider receipt: %v", err)
	}
	if err := service.MarkRead(context.Background(), "ride-1", "7", "peer"); err != nil {
		t.Fatal(err)
	}
	if len(publisher.events) != 1 || publisher.events[0].Type != event.ChatMessagesRead {
		t.Fatalf("receipt events = %v", publisher.events)
	}
	var payload map[string]any
	if err := json.Unmarshal(publisher.events[0].Payload, &payload); err != nil {
		t.Fatal(err)
	}
	if payload["sender_id"] != "7" || payload["read_through"] != "2026-10-23T02:00:00.123456789Z" {
		t.Fatalf("receipt payload = %v", payload)
	}
}

type pictureStore struct {
	content []byte
	deleted bool
}

func (store *pictureStore) Store(_ context.Context, content []byte) (string, error) {
	store.content = bytes.Clone(content)
	return "private-picture", nil
}
func (store *pictureStore) Read(context.Context, string, int64) ([]byte, error) {
	return bytes.Clone(store.content), nil
}
func (store *pictureStore) Delete(context.Context, string) error { store.deleted = true; return nil }

func TestPicturesUsePrivateStorageAndRoomAuthorization(t *testing.T) {
	history := &chatHistory{passengerID: "7", driverID: "8"}
	pictures := &pictureStore{}
	service := application.NewService(application.Dependencies{History: history, Images: pictures}).WithRideAssignmentLookup(chatAssignmentLookup{assignment: assignment.Assignment{RideID: "ride-1", PassengerID: "7", DriverID: "8", Status: "assigned"}, found: true})
	var picture bytes.Buffer
	if err := png.Encode(&picture, image.NewRGBA(image.Rect(0, 0, 2, 2))); err != nil {
		t.Fatal(err)
	}
	if _, err := service.SendImage(context.Background(), "ride-1", "7", []byte("not an image")); !errors.Is(err, domain.ErrInvalidMessage) {
		t.Fatalf("invalid image: %v", err)
	}
	if _, err := service.SendImage(context.Background(), "ride-1", "outsider", picture.Bytes()); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("outsider image: %v", err)
	}
	message, err := service.SendImage(context.Background(), "ride-1", "7", picture.Bytes())
	if err != nil || message.ID == "" || message.ImageKey == "" {
		t.Fatalf("send picture = %#v, %v", message, err)
	}
	content, contentType, err := service.Image(context.Background(), "ride-1", "8", message.ID)
	if err != nil || contentType != "image/png" || !bytes.Equal(content, picture.Bytes()) {
		t.Fatalf("picture read = %s, %v", contentType, err)
	}
	if _, _, err := service.Image(context.Background(), "ride-1", "outsider", message.ID); !errors.Is(err, domain.ErrForbidden) {
		t.Fatalf("outsider picture read: %v", err)
	}
	history.locked = true
	if _, err := service.SendImage(context.Background(), "ride-1", "7", picture.Bytes()); !errors.Is(err, domain.ErrRoomLocked) || !pictures.deleted {
		t.Fatalf("closed picture upload: %v, cleanup %v", err, pictures.deleted)
	}
}
