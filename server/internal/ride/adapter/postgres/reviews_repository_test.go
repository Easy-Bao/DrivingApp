package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestFromPostgresReviewMapsPassengerDetails(t *testing.T) {
	review, err := fromPostgresReview(databasepostgres.ListDriverReviewsRow{
		ID:            19,
		RideID:        pgtype.Int4{Int32: 23, Valid: true},
		DriverID:      7,
		PassengerID:   11,
		PassengerName: "Passenger",
		Rating:        4.5,
		Comment:       pgtype.Text{String: "Great ride", Valid: true},
		CreatedAt: pgtype.Timestamptz{
			Time:  time.Date(2026, time.January, 2, 3, 4, 5, 0, time.FixedZone("PHT", 8*60*60)),
			Valid: true,
		},
	})
	if err != nil {
		t.Fatalf("fromPostgresReview() error = %v", err)
	}
	if review.ID != 19 || review.RideID != 23 || review.PassengerName != "Passenger" || review.Comment != "Great ride" {
		t.Fatalf("mapped review = %+v", review)
	}
	if review.CreatedAt != "2026-01-01T19:04:05Z" {
		t.Fatalf("mapped review creation time = %q", review.CreatedAt)
	}
}

func TestFromPostgresCreatedReviewPreservesNullableRideID(t *testing.T) {
	review, err := fromPostgresCreatedReview(databasepostgres.Review{
		ID:          31,
		DriverID:    7,
		PassengerID: 11,
		CreatedAt:   pgtype.Timestamptz{Time: time.Now(), Valid: true},
	})
	if err != nil {
		t.Fatalf("fromPostgresCreatedReview() error = %v", err)
	}
	if review.RideID != 0 {
		t.Fatalf("nullable ride id = %d, want 0", review.RideID)
	}
}

func TestFromPostgresPassengerReviewRejectsMissingCreationTime(t *testing.T) {
	if _, err := fromPostgresPassengerReview(databasepostgres.PassengerReview{}); err == nil {
		t.Fatal("expected missing passenger review creation time to be rejected")
	}
}
