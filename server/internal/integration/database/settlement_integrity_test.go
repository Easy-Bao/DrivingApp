//go:build integration

package database_test

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
)

func TestSettlementIntegrity(t *testing.T) {
	ctx, cancel := context.WithTimeout(t.Context(), 30*time.Second)
	defer cancel()

	conn := openIsolatedSchemaConn(t, ctx, "settlement_integrity")
	ddl, err := os.ReadFile("../../../db/schema/ride_settlements.sql")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := conn.Exec(ctx, "CREATE TABLE rides (id integer PRIMARY KEY);"+string(ddl)); err != nil {
		t.Fatal(err)
	}
	// Drop the new constraints to model the pre-migration schema.
	if err := executeEmbeddedMigration(ctx, conn, "2026102301_settlement_integrity.down.sql"); err != nil {
		t.Fatal(err)
	}
	if _, err := conn.Exec(ctx, `INSERT INTO rides VALUES (1); INSERT INTO ride_settlements (ride_id,gross_fare,commission_bps) VALUES (1,1000,15000)`); err != nil {
		t.Fatal(err)
	}
	if err := executeEmbeddedMigration(ctx, conn, "2026102301_settlement_integrity.up.sql"); err != nil {
		t.Fatal(err)
	}
	var legacyRate int
	if err := conn.QueryRow(ctx, "SELECT commission_bps FROM ride_settlements WHERE ride_id=1").Scan(&legacyRate); err != nil || legacyRate != 15000 {
		t.Fatalf("legacy data changed: %d %v", legacyRate, err)
	}
	cases := []struct {
		name, status, outcome string
		rate                  *int
		received, change      int64
		valid                 bool
	}{
		{"initial", "unpaid", "unpaid", new(1500), 0, 0, true},
		{"legacy null rate", "unpaid", "unpaid", nil, 0, 0, true},
		{"paid with change", "paid", "paid", new(10000), 1200, 200, true},
		{"partial", "unpaid", "partial", new(0), 400, 0, true},
		{"refused", "unpaid", "refused", nil, 0, 0, true},
		{"returned cash", "unpaid", "unpaid", nil, 500, 500, true},
		{"disputed", "unpaid", "disputed", nil, 700, 0, true},
		{"high rate", "unpaid", "unpaid", new(15000), 0, 0, false},
		{"negative rate", "unpaid", "unpaid", new(-1), 0, 0, false},
		{"paid without cash", "paid", "paid", nil, 0, 0, false},
		{"paid unpaid outcome", "paid", "unpaid", nil, 0, 0, false},
		{"unpaid paid outcome", "unpaid", "paid", nil, 1000, 0, false},
		{"partial full fare", "unpaid", "partial", nil, 1000, 0, false},
		{"partial zero", "unpaid", "partial", nil, 0, 0, false},
		{"partial change", "unpaid", "partial", nil, 500, 100, false},
		{"refused retains cash", "unpaid", "refused", nil, 100, 0, false},
	}
	for i, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			id := i + 2
			if _, err := conn.Exec(ctx, "INSERT INTO rides VALUES ($1)", id); err != nil {
				t.Fatal(err)
			}
			_, err := conn.Exec(ctx, `INSERT INTO ride_settlements (ride_id,gross_fare,commission_bps,commission_amount,driver_payout_amount,payment_status,cash_outcome,cash_received_amount,cash_change_amount) VALUES ($1,1000,$2,150,850,$3,$4,$5,$6)`, id, tc.rate, tc.status, tc.outcome, tc.received, tc.change)
			if tc.valid {
				if err != nil {
					t.Fatal(err)
				}
				return
			}
			pgErr, ok := errors.AsType[*pgconn.PgError](err)
			if !ok || pgErr.Code != "23514" {
				t.Fatalf("want check violation, got %v", err)
			}
		})
	}
	if _, err := conn.Exec(ctx, "UPDATE ride_settlements SET commission_bps=15000 WHERE ride_id=2"); err == nil {
		t.Fatal("invalid update accepted")
	}
	if _, err := conn.Exec(ctx, "UPDATE ride_settlements SET commission_bps=NULL WHERE ride_id=1"); err != nil {
		t.Fatal(err)
	}
	if _, err := conn.Exec(ctx, `ALTER TABLE ride_settlements VALIDATE CONSTRAINT ride_settlements_commission_range_check, VALIDATE CONSTRAINT ride_settlements_payment_outcome_check, VALIDATE CONSTRAINT ride_settlements_cash_collection_check`); err != nil {
		t.Fatal(err)
	}
	if err := executeEmbeddedMigration(ctx, conn, "2026102301_settlement_integrity.down.sql"); err != nil {
		t.Fatal(err)
	}
	if _, err := conn.Exec(ctx, "UPDATE ride_settlements SET commission_bps=15000 WHERE ride_id=2"); err != nil {
		t.Fatal(err)
	}
}
