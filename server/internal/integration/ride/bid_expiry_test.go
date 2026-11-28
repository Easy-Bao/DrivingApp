//go:build integration

package ride_test

import (
	"context"
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestBidExpiryBatchSkipsLocksAndBreaksTiesByID(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()
	now := time.Now().UTC()
	var sessionIDs []int
	for _, passengerID := range []int{101, 102, 103, 104, 105} {
		fixture.seedPassenger(t, ctx, passengerID)
		sessionIDs = append(sessionIDs, fixture.createBidSession(t, ctx, passengerID))
	}
	fixture.seedDriver(t, ctx, 201)
	offerID := fixture.createBidOffer(t, ctx, sessionIDs[1], 201)
	if _, err := fixture.pool.Exec(ctx, `
UPDATE bid_sessions
SET expires_at = CASE WHEN id = $1 THEN $2::timestamptz ELSE $3::timestamptz END,
    status = CASE WHEN id = $4 THEN 'cancelled' ELSE status END`,
		sessionIDs[4], now.Add(time.Minute), now.Add(-time.Minute), sessionIDs[3]); err != nil {
		t.Fatal(err)
	}

	locked, err := fixture.pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = locked.Rollback(ctx) }()
	if _, err := locked.Exec(ctx, "SELECT id FROM bid_sessions WHERE id = $1 FOR UPDATE", sessionIDs[0]); err != nil {
		t.Fatal(err)
	}
	rows, err := databasepostgres.New(fixture.pool).ExpireAllElapsedBidSessions(ctx, databasepostgres.ExpireAllElapsedBidSessionsParams{
		ExpiresAt: pgtype.Timestamptz{Time: now, Valid: true},
		Limit:     1,
	})
	if err != nil || rows != 1 {
		t.Fatalf("first expiry batch processed %d rows: %v", rows, err)
	}
	assertRowCount(t, ctx, fixture.pool, "SELECT count(*) FROM bid_offers WHERE status = 'rejected' AND id = $1", offerID, 1)
	assertRowCount(t, ctx, fixture.pool, "SELECT count(*) FROM notifications WHERE user_id = $1", 102, 1)
	if err := locked.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if rows, err := fixture.dispatchStore.ExpireAllElapsedBidSessions(ctx, now, 1); err != nil || rows != 2 {
		t.Fatalf("remaining expiry batches processed %d rows: %v", rows, err)
	}
	if rows, err := fixture.dispatchStore.ExpireAllElapsedBidSessions(ctx, now, 1); err != nil || rows != 0 {
		t.Fatalf("repeated expiry sweep processed %d rows: %v", rows, err)
	}
	assertRowCount(t, ctx, fixture.pool, "SELECT count(DISTINCT user_id) FROM notifications WHERE user_id = ANY($1::int[])", []int32{101, 102, 103}, 3)
	assertRowCount(t, ctx, fixture.pool, "SELECT count(*) FROM notifications WHERE user_id = ANY($1::int[])", []int32{101, 102, 103, 104, 105}, 3)
}
