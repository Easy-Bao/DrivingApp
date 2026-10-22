package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestNewStoreRequiresPostgresPool(t *testing.T) {
	if _, err := NewStore(StoreConfig{}); err == nil {
		t.Fatal("NewStore() succeeded without a PostgreSQL pool")
	}
}

func TestAcceptedRideProjectionPreservesRideAndSettlementSnapshot(t *testing.T) {
	createdAt := time.Date(2026, time.October, 12, 10, 30, 0, 0, time.UTC)
	commissionBPS := int32(1500)
	ride, err := fromPostgresAcceptedRideProjection(
		databasepostgres.Ride{
			ID:          17,
			PassengerID: 7,
			DriverID:    pgtype.Int4{Int32: 11, Valid: true},
			Status:      "assigned",
			FareAmount:  5000,

			PickupLatitude:   pgtype.Float8{Float64: 14.5, Valid: true},
			PickupLongitude:  pgtype.Float8{Float64: 121.0, Valid: true},
			PickupName:       pgtype.Text{String: "Origin", Valid: true},
			DropoffLatitude:  pgtype.Float8{Float64: 14.6, Valid: true},
			DropoffLongitude: pgtype.Float8{Float64: 121.1, Valid: true},
			DropoffName:      pgtype.Text{String: "Destination", Valid: true},
			CreatedAt:        bidTimestamp(createdAt),
		},
		databasepostgres.RideSettlement{
			CommissionBps:      pgtype.Int4{Int32: commissionBPS, Valid: true},
			CommissionAmount:   750,
			DriverPayoutAmount: 4250,
			PaymentStatus:      "unpaid",
			CashOutcome:        "unpaid",
		},
	)
	if err != nil {
		t.Fatalf("fromPostgresAcceptedRideProjection() error = %v", err)
	}
	if ride.ID != 17 || ride.PassengerID != 7 || ride.DriverID == nil || *ride.DriverID != 11 ||
		ride.FareAmount != 5000 || ride.PickupName != "Origin" || ride.DropoffName != "Destination" ||
		ride.CommissionBPS == nil || *ride.CommissionBPS != int64(commissionBPS) ||
		ride.CommissionAmount != 750 || ride.DriverPayoutAmount != 4250 {
		t.Fatalf("accepted ride snapshot = %+v", ride)
	}
	if ride.CreatedAt == nil || *ride.CreatedAt != createdAt.Format(time.RFC3339) {
		t.Fatalf("accepted ride creation time = %v, want %s", ride.CreatedAt, createdAt.Format(time.RFC3339))
	}
}
