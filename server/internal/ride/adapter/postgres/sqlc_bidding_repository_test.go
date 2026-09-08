package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestFromPostgresBidSessionMapsNullableIdentityFields(t *testing.T) {
	item := databasepostgres.BidSession{
		ID:             17,
		PassengerID:    7,
		RideType:       "solo",
		PassengerNote:  pgtype.Text{String: "Call on arrival", Valid: true},
		TargetDriverID: pgtype.Int4{Int32: 11, Valid: true},
		ExpiresAt:      bidTimestamp(time.Date(2026, time.January, 2, 3, 4, 5, 0, time.UTC)),
		CreatedAt:      bidTimestamp(time.Date(2026, time.January, 2, 3, 0, 0, 0, time.UTC)),
	}

	session, err := fromPostgresBidSession(item)
	if err != nil {
		t.Fatalf("fromPostgresBidSession() error = %v", err)
	}
	if session.ID != 17 || session.PassengerNote != "Call on arrival" || session.TargetDriverID == nil || *session.TargetDriverID != 11 {
		t.Fatalf("mapped bid session = %+v", session)
	}
}

func TestFromPostgresBidOfferMapsDriverSnapshot(t *testing.T) {
	offer, err := fromPostgresBidOffer(databasepostgres.BidOffer{
		ID:                   23,
		SessionID:            17,
		DriverID:             11,
		DriverName:           pgtype.Text{String: "Ada", Valid: true},
		VehicleType:          pgtype.Text{String: "sedan", Valid: true},
		ProposedFareCentavos: 3200,
		Status:               "pending",
		CreatedAt:            bidTimestamp(time.Now()),
	})
	if err != nil {
		t.Fatalf("fromPostgresBidOffer() error = %v", err)
	}
	if offer.ID != 23 || offer.DriverName != "Ada" || offer.VehicleType != "sedan" || offer.ProposedFareCentavos != 3200 {
		t.Fatalf("mapped bid offer = %+v", offer)
	}
}

func TestFromPostgresBiddingRowsRejectMissingTimestamps(t *testing.T) {
	if _, err := fromPostgresBidSession(databasepostgres.BidSession{}); err == nil {
		t.Fatal("expected missing bid session timestamp to be rejected")
	}
	if _, err := fromPostgresBidOffer(databasepostgres.BidOffer{}); err == nil {
		t.Fatal("expected missing bid offer timestamp to be rejected")
	}
}
