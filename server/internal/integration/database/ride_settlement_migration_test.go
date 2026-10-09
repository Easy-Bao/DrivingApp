//go:build integration

package database_test

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
)

func TestRideSettlementAuthorityMigrationPreservesFinancialData(t *testing.T) {
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	admin, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("connect to test PostgreSQL database: %v", err)
	}

	schemaName := fmt.Sprintf("ride_settlement_it_%d", time.Now().UnixNano())
	quotedSchema := pgx.Identifier{schemaName}.Sanitize()
	if _, err := admin.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		_ = admin.Close(context.Background())
		t.Fatalf("create isolated test schema: %v", err)
	}

	var connection *pgx.Conn
	t.Cleanup(func() {
		cleanupContext, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		if connection != nil {
			_ = connection.Close(cleanupContext)
		}
		_, _ = admin.Exec(cleanupContext, "DROP SCHEMA "+quotedSchema+" CASCADE")
		_ = admin.Close(cleanupContext)
	})

	config, err := pgx.ParseConfig(databaseURL)
	if err != nil {
		t.Fatalf("parse test PostgreSQL connection: %v", err)
	}
	config.RuntimeParams["search_path"] = schemaName
	connection, err = pgx.ConnectConfig(ctx, config)
	if err != nil {
		t.Fatalf("connect to isolated test schema: %v", err)
	}

	_, err = connection.Exec(ctx, `
CREATE TABLE rides (
    id integer PRIMARY KEY,
    status text NOT NULL,
    fare_amount bigint NOT NULL,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    cash_received_amount bigint NOT NULL DEFAULT 0,
    cash_change_amount bigint NOT NULL DEFAULT 0,
    cash_outcome text NOT NULL DEFAULT 'unpaid',
    commission_bps integer,
    commission_amount bigint NOT NULL DEFAULT 0,
    driver_payout_amount bigint NOT NULL DEFAULT 0,
    cancellation_details text NOT NULL DEFAULT '',
    CONSTRAINT rides_payment_status_check CHECK (payment_status IN ('unpaid', 'paid')),
    CONSTRAINT rides_cash_amounts_check CHECK (
        cash_received_amount >= 0
        AND cash_change_amount >= 0
        AND cash_change_amount <= cash_received_amount
    ),
    CONSTRAINT rides_cash_outcome_check CHECK (
        cash_outcome IN ('paid', 'partial', 'refused', 'unpaid', 'disputed')
    ),
    CONSTRAINT rides_money_check CHECK (
        fare_amount >= 0
        AND cash_received_amount >= 0
        AND cash_change_amount >= 0
        AND cash_change_amount <= cash_received_amount
        AND cancellation_details IS NOT NULL
        AND commission_amount >= 0
        AND driver_payout_amount >= 0
    )
);`)
	if err != nil {
		t.Fatalf("create legacy rides table: %v", err)
	}
	_, err = connection.Exec(ctx, `
CREATE TABLE ride_settlements (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    gross_fare bigint NOT NULL,
    commission_bps integer,
    commission_amount bigint NOT NULL DEFAULT 0,
    driver_payout_amount bigint NOT NULL DEFAULT 0,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    cash_received_amount bigint NOT NULL DEFAULT 0,
    cash_change_amount bigint NOT NULL DEFAULT 0,
    cash_outcome text NOT NULL DEFAULT 'unpaid',
    settled_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);`)
	if err != nil {
		t.Fatalf("create legacy settlements table: %v", err)
	}
	if _, err := connection.Exec(ctx, "CREATE UNIQUE INDEX ridesettlement_ride_id ON ride_settlements (ride_id)"); err != nil {
		t.Fatalf("create unique ride settlement index: %v", err)
	}
	_, err = connection.Exec(ctx, `INSERT INTO rides VALUES
    (1, 'completed', 1000, 'paid', '2026-10-01 10:00:00+08', 1100, 100, 'paid', 1500, 150, 850, ''),
    (2, 'assigned', 2000, 'unpaid', NULL, 0, 0, 'unpaid', 1000, 200, 1800, ''),
    (3, 'requested', 3000, 'unpaid', NULL, 0, 0, 'unpaid', NULL, 0, 0, ''),
    (4, 'requested', 500, 'unpaid', NULL, 0, 0, 'unpaid', 500, 25, 475, ''),
    (5, 'completed', 1000, 'paid', '2026-10-03 12:00:00+08', 1000, 0, 'paid', 1500, 150, 850, '')`)
	if err != nil {
		t.Fatalf("seed legacy ride financial state: %v", err)
	}
	_, err = connection.Exec(ctx, `INSERT INTO ride_settlements (
    ride_id, gross_fare, commission_bps, commission_amount,
    driver_payout_amount, payment_status, cash_received_at,
    cash_received_amount, cash_change_amount, cash_outcome, settled_at
)
VALUES (
    1, 1000, 1000, 100, 900, 'paid',
    '2026-10-01 10:00:00+08', 1000, 0, 'paid', '2026-10-01 10:00:00+08'
)`)
	if err != nil {
		t.Fatalf("seed existing ride settlement: %v", err)
	}

	if err := executeEmbeddedMigration(ctx, connection, "2026100911_ride_settlements_authoritative.up.sql"); err != nil {
		t.Fatalf("apply settlement authority migration: %v", err)
	}

	var duplicateColumnCount int
	if err := connection.QueryRow(ctx, `
SELECT count(*)
FROM information_schema.columns
WHERE table_schema = current_schema()
  AND table_name = 'rides'
  AND column_name IN (
      'payment_status', 'cash_received_at', 'cash_received_amount',
      'cash_change_amount', 'cash_outcome', 'commission_bps',
      'commission_amount', 'driver_payout_amount'
  )`).Scan(&duplicateColumnCount); err != nil {
		t.Fatalf("check normalized ride columns: %v", err)
	}
	if duplicateColumnCount != 0 {
		t.Fatalf("rides retains %d settlement columns after migration", duplicateColumnCount)
	}

	assertSettlement := func(
		rideID int32,
		grossFare, commissionAmount, payout, cashReceived, cashChange int64,
		commissionBPS int32,
		paymentStatus, cashOutcome string,
	) {
		t.Helper()
		var gotGrossFare, gotCommissionAmount, gotPayout, gotCashReceived, gotCashChange int64
		var gotCommissionBPS int32
		var gotPaymentStatus, gotCashOutcome string
		err := connection.QueryRow(ctx, `
SELECT gross_fare, commission_bps, commission_amount, driver_payout_amount,
       payment_status, cash_received_amount, cash_change_amount, cash_outcome
FROM ride_settlements
WHERE ride_id = $1`, rideID).Scan(
			&gotGrossFare,
			&gotCommissionBPS,
			&gotCommissionAmount,
			&gotPayout,
			&gotPaymentStatus,
			&gotCashReceived,
			&gotCashChange,
			&gotCashOutcome,
		)
		if err != nil {
			t.Fatalf("read settlement for ride %d: %v", rideID, err)
		}
		if gotGrossFare != grossFare || gotCommissionBPS != commissionBPS ||
			gotCommissionAmount != commissionAmount || gotPayout != payout ||
			gotCashReceived != cashReceived || gotCashChange != cashChange ||
			gotPaymentStatus != paymentStatus || gotCashOutcome != cashOutcome {
			t.Fatalf("settlement for ride %d = (%d, %d, %d, %d, %s, %d, %d, %s)",
				rideID, gotGrossFare, gotCommissionBPS, gotCommissionAmount, gotPayout,
				gotPaymentStatus, gotCashReceived, gotCashChange, gotCashOutcome)
		}
	}

	assertSettlement(1, 1000, 100, 900, 1000, 0, 1000, "paid", "paid")
	assertSettlement(2, 2000, 200, 1800, 0, 0, 1000, "unpaid", "unpaid")
	assertSettlement(4, 500, 25, 475, 0, 0, 500, "unpaid", "unpaid")
	assertSettlement(5, 1000, 150, 850, 1000, 0, 1500, "paid", "paid")

	var settledAtMatchesCashReceivedAt bool
	if err := connection.QueryRow(ctx, `
SELECT settled_at = cash_received_at
FROM ride_settlements
WHERE ride_id = 5`).Scan(&settledAtMatchesCashReceivedAt); err != nil {
		t.Fatalf("check migrated settlement time: %v", err)
	}
	if !settledAtMatchesCashReceivedAt {
		t.Fatal("paid historical ride did not preserve its cash settlement time")
	}

	var untouchedRequestedRideHasSettlement bool
	if err := connection.QueryRow(ctx, `
SELECT EXISTS (SELECT 1 FROM ride_settlements WHERE ride_id = 3)`).Scan(&untouchedRequestedRideHasSettlement); err != nil {
		t.Fatalf("check untouched requested ride: %v", err)
	}
	if untouchedRequestedRideHasSettlement {
		t.Fatal("untouched requested ride unexpectedly received a settlement")
	}

	if _, err := connection.Exec(ctx, `
UPDATE ride_settlements
SET commission_bps = 2000, commission_amount = 200, driver_payout_amount = 800,
    cash_received_at = '2026-10-02 11:00:00+08',
    cash_received_amount = 1200, cash_change_amount = 200
WHERE ride_id = 1`); err != nil {
		t.Fatalf("update authoritative settlement before rollback: %v", err)
	}
	if err := executeEmbeddedMigration(ctx, connection, "2026100911_ride_settlements_authoritative.down.sql"); err != nil {
		t.Fatalf("roll back settlement authority migration: %v", err)
	}

	var restoredCommissionBPS int32
	var restoredCommission, restoredPayout, restoredCashReceived, restoredCashChange int64
	if err := connection.QueryRow(ctx, `
SELECT commission_bps, commission_amount, driver_payout_amount,
       cash_received_amount, cash_change_amount
FROM rides
WHERE id = 1`).Scan(
		&restoredCommissionBPS,
		&restoredCommission,
		&restoredPayout,
		&restoredCashReceived,
		&restoredCashChange,
	); err != nil {
		t.Fatalf("read restored ride financial columns: %v", err)
	}
	if restoredCommissionBPS != 2000 || restoredCommission != 200 ||
		restoredPayout != 800 || restoredCashReceived != 1200 || restoredCashChange != 200 {
		t.Fatalf("rollback restored settlement = (%d, %d, %d, %d, %d)",
			restoredCommissionBPS, restoredCommission, restoredPayout,
			restoredCashReceived, restoredCashChange)
	}

	for _, expected := range []struct {
		rideID             int32
		commissionBPS      int32
		commissionAmount   int64
		driverPayoutAmount int64
	}{
		{rideID: 2, commissionBPS: 1000, commissionAmount: 200, driverPayoutAmount: 1800},
		{rideID: 4, commissionBPS: 500, commissionAmount: 25, driverPayoutAmount: 475},
		{rideID: 5, commissionBPS: 1500, commissionAmount: 150, driverPayoutAmount: 850},
	} {
		var commissionBPS int32
		var commissionAmount, driverPayoutAmount int64
		if err := connection.QueryRow(ctx, `
SELECT commission_bps, commission_amount, driver_payout_amount
FROM rides
WHERE id = $1`, expected.rideID).Scan(&commissionBPS, &commissionAmount, &driverPayoutAmount); err != nil {
			t.Fatalf("read restored ride %d financial columns: %v", expected.rideID, err)
		}
		if commissionBPS != expected.commissionBPS || commissionAmount != expected.commissionAmount ||
			driverPayoutAmount != expected.driverPayoutAmount {
			t.Fatalf("rollback restored ride %d settlement = (%d, %d, %d)",
				expected.rideID, commissionBPS, commissionAmount, driverPayoutAmount)
		}
	}

	var untouchedPaymentStatus, untouchedCashOutcome string
	var untouchedCommission, untouchedPayout int64
	if err := connection.QueryRow(ctx, `
SELECT payment_status, cash_outcome, commission_amount, driver_payout_amount
FROM rides
WHERE id = 3`).Scan(
		&untouchedPaymentStatus,
		&untouchedCashOutcome,
		&untouchedCommission,
		&untouchedPayout,
	); err != nil {
		t.Fatalf("read untouched requested ride after rollback: %v", err)
	}
	if untouchedPaymentStatus != "unpaid" || untouchedCashOutcome != "unpaid" ||
		untouchedCommission != 0 || untouchedPayout != 0 {
		t.Fatalf("untouched requested ride financial defaults = (%s, %s, %d, %d)",
			untouchedPaymentStatus, untouchedCashOutcome, untouchedCommission, untouchedPayout)
	}

}
