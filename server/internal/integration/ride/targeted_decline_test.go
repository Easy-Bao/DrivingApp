//go:build integration

package ride_test

import (
	"errors"
	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"os"
	"testing"
)

func TestTargetedDeclineAuthorizationAndIdempotency(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx := t.Context()
	fixture.seedPassenger(t, ctx, 101)
	fixture.seedDriver(t, ctx, 201)
	fixture.seedDriver(t, ctx, 202)
	sessionID := fixture.createBidSession(t, ctx, 101)
	if _, err := fixture.dispatchStore.DeclineSession(ctx, sessionID, 201); !errors.Is(err, dispatchdomain.ErrUnauthorizedSession) {
		t.Fatalf("untargeted decline = %v", err)
	}
	if _, err := fixture.pool.Exec(ctx, "UPDATE bid_sessions SET target_driver_id = 201 WHERE id = $1", sessionID); err != nil {
		t.Fatal(err)
	}
	if _, err := fixture.dispatchStore.DeclineSession(ctx, sessionID, 202); !errors.Is(err, dispatchdomain.ErrUnauthorizedSession) {
		t.Fatalf("wrong driver decline = %v", err)
	}
	for range 2 {
		session, err := fixture.dispatchStore.DeclineSession(ctx, sessionID, 201)
		if err != nil || session.Status != "declined" || session.TargetDriverID == nil || *session.TargetDriverID != 201 {
			t.Fatalf("decline = %+v, %v", session, err)
		}
	}
	if _, err := fixture.dispatchStore.DeclineSession(ctx, sessionID+999, 201); !errors.Is(err, dispatchdomain.ErrSessionNotFound) {
		t.Fatalf("missing session = %v", err)
	}
}

func TestTargetedDeclineRejectsClosedSessions(t *testing.T) {
	for _, state := range []string{"accepted", "cancelled", "expired", "open"} {
		t.Run(state, func(t *testing.T) {
			fixture := newPostgresRideFixture(t)
			ctx := t.Context()
			fixture.seedPassenger(t, ctx, 101)
			fixture.seedDriver(t, ctx, 201)
			id := fixture.createBidSession(t, ctx, 101)
			if _, err := fixture.pool.Exec(ctx, "UPDATE bid_sessions SET target_driver_id = 201, status = $2, expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second' WHERE id = $1", id, state); err != nil {
				t.Fatal(err)
			}
			if _, err := fixture.dispatchStore.DeclineSession(ctx, id, 201); !errors.Is(err, dispatchdomain.ErrSessionClosed) {
				t.Fatalf("closed decline = %v", err)
			}
		})
	}
}

func TestTargetedDeclineRacesAcceptance(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx := t.Context()
	fixture.seedPassenger(t, ctx, 101)
	fixture.seedDriver(t, ctx, 201)
	id := fixture.createBidSession(t, ctx, 101)
	if _, err := fixture.pool.Exec(ctx, "UPDATE bid_sessions SET target_driver_id = 201 WHERE id = $1", id); err != nil {
		t.Fatal(err)
	}
	offerID := fixture.createBidOffer(t, ctx, id, 201)
	start := make(chan struct{})
	accepted := make(chan error, 1)
	declined := make(chan error, 1)
	go func() { <-start; _, err := fixture.dispatchStore.AcceptOffer(ctx, id, offerID, 101); accepted <- err }()
	go func() { <-start; _, err := fixture.dispatchStore.DeclineSession(ctx, id, 201); declined <- err }()
	close(start)
	acceptErr, declineErr := <-accepted, <-declined
	if (acceptErr == nil) == (declineErr == nil) {
		t.Fatalf("accept = %v, decline = %v; want one winner", acceptErr, declineErr)
	}
	session, err := fixture.dispatchStore.Session(ctx, id)
	if err != nil {
		t.Fatal(err)
	}
	wantRides := 0
	if acceptErr == nil {
		wantRides = 1
		if session.Status != "accepted" {
			t.Fatalf("state = %s", session.Status)
		}
	} else if session.Status != "declined" {
		t.Fatalf("state = %s", session.Status)
	}
	assertRowCount(t, ctx, fixture.pool, "SELECT count(*) FROM rides WHERE bid_session_id = $1", id, wantRides)
}

func TestTargetedDeclineMigrationRoundTrip(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx := t.Context()
	fixture.seedPassenger(t, ctx, 101)
	fixture.seedDriver(t, ctx, 201)
	id := fixture.createBidSession(t, ctx, 101)
	if _, err := fixture.pool.Exec(ctx, "UPDATE bid_sessions SET target_driver_id = 201 WHERE id = $1", id); err != nil {
		t.Fatal(err)
	}
	apply := func(direction string) {
		t.Helper()
		migration, err := os.ReadFile("../../../db/migrations/2026102401_targeted_session_decline." + direction + ".sql")
		if err != nil {
			t.Fatal(err)
		}
		if _, err := fixture.pool.Exec(ctx, string(migration)); err != nil {
			t.Fatal(err)
		}
	}
	apply("down")
	apply("up")
	if _, err := fixture.dispatchStore.DeclineSession(ctx, id, 201); err != nil {
		t.Fatal(err)
	}
	apply("down")
	session, err := fixture.dispatchStore.Session(ctx, id)
	if err != nil || session.Status != "cancelled" || session.TargetDriverID == nil || *session.TargetDriverID != 201 {
		t.Fatalf("rolled back session = %+v, %v", session, err)
	}
	apply("up")
}
