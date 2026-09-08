package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestNewPostgresProfileRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewPostgresProfileRepository(nil, nil); err == nil {
		t.Fatal("expected nil PostgreSQL pool to be rejected")
	}
}

func TestProfileTextValue(t *testing.T) {
	if got := profileTextValue(pgtype.Text{String: "Quezon City", Valid: true}); got != "Quezon City" {
		t.Fatalf("valid text = %q, want Quezon City", got)
	}
	if got := profileTextValue(pgtype.Text{}); got != "" {
		t.Fatalf("invalid text = %q, want empty string", got)
	}
}

func TestProfileMappingsPreserveAccountContactDetails(t *testing.T) {
	account := databasepostgres.User{
		Phone: "+639000000000",
		Email: "user@example.com",
	}
	driver := driverProfileFromPostgres(account, databasepostgres.DriverProfile{
		ID:          17,
		UserID:      11,
		Name:        "Driver",
		VehicleType: "sedan",
		PlateNumber: "ABC123",
		Rating:      4.8,
		IsOnline:    true,
	})
	if driver.Role != "driver" || driver.Phone != account.Phone || driver.Email != account.Email || !driver.IsOnline {
		t.Fatalf("driver profile = %+v", driver)
	}

	passenger := passengerProfileFromPostgres(account, databasepostgres.PassengerProfile{
		ID:                23,
		UserID:            11,
		Name:              "Passenger",
		Address:           pgtype.Text{String: "Makati", Valid: true},
		Gender:            domain.DefaultGender,
		AvatarStorageKey:  pgtype.Text{String: "db/v1/avatar", Valid: true},
		PreferredRideType: pgtype.Text{String: "solo-ride", Valid: true},
	})
	if passenger.Role != "passenger" || passenger.Address != "Makati" || passenger.AvatarURL == "" || passenger.PreferredRideType != "solo-ride" {
		t.Fatalf("passenger profile = %+v", passenger)
	}
}

func TestPostgresProfileIDAndPageBounds(t *testing.T) {
	if got, err := toPostgresProfileID(7, "user id"); err != nil || got != 7 {
		t.Fatalf("toPostgresProfileID(7) = %d, %v", got, err)
	}
	for _, value := range []int{0, -1, maxPostgresProfileID + 1} {
		if _, err := toPostgresProfileID(value, "user id"); err == nil {
			t.Errorf("toPostgresProfileID(%d) succeeded", value)
		}
	}
	if got, err := toPostgresProfilePageValue(0, "offset"); err != nil || got != 0 {
		t.Fatalf("toPostgresProfilePageValue(0) = %d, %v", got, err)
	}
	for _, value := range []int{-1, maxPostgresProfileID + 1} {
		if _, err := toPostgresProfilePageValue(value, "offset"); err == nil {
			t.Errorf("toPostgresProfilePageValue(%d) succeeded", value)
		}
	}
}

func TestPostgresNotificationMappingUsesUTC(t *testing.T) {
	notification, err := fromPostgresNotification(databasepostgres.Notification{
		ID:     9,
		UserID: 11,
		Type:   "ride",
		CreatedAt: pgtype.Timestamptz{
			Time:  time.Date(2026, time.January, 2, 3, 4, 5, 0, time.FixedZone("PHT", 8*60*60)),
			Valid: true,
		},
	})
	if err != nil {
		t.Fatalf("fromPostgresNotification() error = %v", err)
	}
	if notification.ID != 9 || notification.UserID != 11 || notification.CreatedAt != "2026-01-01T19:04:05Z" {
		t.Fatalf("mapped notification = %+v", notification)
	}

	if _, err := fromPostgresNotification(databasepostgres.Notification{}); err == nil {
		t.Fatal("expected invalid notification timestamp to be rejected")
	}
	if _, err := toPostgresProfilePageValue(-1, "offset"); err == nil {
		t.Fatal("expected negative notification offset to be rejected")
	}
}
