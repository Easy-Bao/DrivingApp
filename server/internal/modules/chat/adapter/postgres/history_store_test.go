package postgres

import (
	"context"
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestNewHistoryStoreRequiresPool(t *testing.T) {
	if _, err := NewHistoryStore(nil); err == nil {
		t.Fatal("NewHistoryStore(nil) succeeded, want error")
	}
	var nilStore *HistoryStore
	if err := nilStore.CreateRoom(context.Background(), "room-1", "1", "2"); err == nil {
		t.Fatal("nil store CreateRoom succeeded, want error")
	}
	if _, _, err := nilStore.FindMessage(context.Background(), "room-1", "msg-1"); err == nil {
		t.Fatal("nil store FindMessage succeeded, want error")
	}
	if err := nilStore.ImportRoomState(context.Background(), LegacyRoomSnapshot{RoomID: "room-1"}); err == nil {
		t.Fatal("nil store ImportRoomState succeeded, want error")
	}
}

func TestMapPostgresMessageComputesReadWatermarkPerParticipant(t *testing.T) {
	t1 := time.Date(2026, 11, 27, 8, 0, 0, 0, time.UTC)
	t2 := t1.Add(time.Minute)
	room := databasepostgres.ChatRoom{
		RoomID:               "ride-1",
		PassengerID:          "7",
		DriverID:             "8",
		PassengerReadThrough: pgtype.Timestamptz{Time: t1, Valid: true},
		DriverReadThrough:    pgtype.Timestamptz{Time: t2, Valid: true},
	}

	fromPassenger := mapPostgresMessage(databasepostgres.ChatMessage{
		ID:        "m1",
		RoomID:    "ride-1",
		SenderID:  "7",
		Body:      "hi",
		CreatedAt: pgtype.Timestamptz{Time: t2, Valid: true},
	}, room)
	if !fromPassenger.Seen {
		t.Fatalf("expected passenger message at driver watermark to be Seen: %#v", fromPassenger)
	}

	fromDriverAfterPassengerRead := mapPostgresMessage(databasepostgres.ChatMessage{
		ID:        "m2",
		RoomID:    "ride-1",
		SenderID:  "8",
		Body:      "omw",
		CreatedAt: pgtype.Timestamptz{Time: t2, Valid: true},
	}, room)
	if fromDriverAfterPassengerRead.Seen {
		t.Fatalf("expected driver message after passenger watermark not to be Seen: %#v", fromDriverAfterPassengerRead)
	}
}
