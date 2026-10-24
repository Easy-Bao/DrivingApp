//go:build integration

package ride_test

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	dispatchpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/adapter/postgres"
	ridepostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/adapter/postgres"
	ridelifecycle "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestConcurrentOfferAcceptanceCreatesOneRideAndSettlement(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const passengerID = 101
	const firstDriverID = 201
	const secondDriverID = 202
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, firstDriverID)
	fixture.seedDriver(t, ctx, secondDriverID)
	sessionID := fixture.createBidSession(t, ctx, passengerID)
	firstOfferID := fixture.createBidOffer(t, ctx, sessionID, firstDriverID)
	secondOfferID := fixture.createBidOffer(t, ctx, sessionID, secondDriverID)

	start := make(chan struct{})
	results := make(chan error, 2)
	for _, offerID := range []int{firstOfferID, secondOfferID} {
		go func(offerID int) {
			<-start
			_, err := fixture.dispatchStore.AcceptOffer(ctx, sessionID, offerID, passengerID)
			results <- err
		}(offerID)
	}
	close(start)
	firstErr := <-results
	secondErr := <-results
	if (firstErr == nil) == (secondErr == nil) {
		t.Fatalf("offer acceptances returned (%v, %v), want exactly one success", firstErr, secondErr)
	}

	var sessionStatus string
	var acceptedDriverID pgtype.Int4
	if err := fixture.pool.QueryRow(ctx, `
SELECT status, accepted_driver_id
FROM bid_sessions
WHERE id = $1`, sessionID).Scan(&sessionStatus, &acceptedDriverID); err != nil {
		t.Fatalf("read accepted session: %v", err)
	}
	if sessionStatus != "accepted" || !acceptedDriverID.Valid {
		t.Fatalf("session state = (%q, %v), want accepted session with a driver", sessionStatus, acceptedDriverID)
	}
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM bid_offers
WHERE session_id = $1 AND status = 'accepted'`, sessionID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM bid_offers
WHERE session_id = $1 AND status = 'rejected'`, sessionID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM rides WHERE passenger_id = $1`, passengerID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM ride_settlements AS settlement
JOIN rides ON rides.id = settlement.ride_id
WHERE rides.passenger_id = $1`, passengerID, 1)
}

func TestConcurrentBookingReferenceAllocation(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	results := make(chan string, 32)
	failures := make(chan error, 32)
	var workers sync.WaitGroup
	for range 32 {
		workers.Go(func() {
			var reference string
			err := fixture.pool.QueryRow(t.Context(), "SELECT allocate_booking_reference()").Scan(&reference)
			if err != nil {
				failures <- err
				return
			}
			results <- reference
		})
	}
	workers.Wait()
	close(results)
	close(failures)
	for err := range failures {
		t.Fatalf("allocate concurrent reference: %v", err)
	}
	unique := make(map[string]bool)
	for reference := range results {
		if unique[reference] {
			t.Fatalf("duplicate reference: %q", reference)
		}
		unique[reference] = true
	}
	if len(unique) != 32 {
		t.Fatalf("allocated %d references, want 32", len(unique))
	}
}

func TestBookingReferenceSurvivesOfferAcceptance(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx := t.Context()
	fixture.seedPassenger(t, ctx, 501)
	fixture.seedDriver(t, ctx, 601)
	sessionID := fixture.createBidSession(t, ctx, 501)
	offerID := fixture.createBidOffer(t, ctx, sessionID, 601)
	session, err := fixture.dispatchStore.Session(ctx, sessionID)
	if err != nil {
		t.Fatal(err)
	}
	accepted, err := fixture.dispatchStore.AcceptOffer(ctx, sessionID, offerID, 501)
	if err != nil {
		t.Fatal(err)
	}
	if len(session.BookingReference) != 15 || session.BookingReference[:4] != "7016" ||
		accepted.Session.BookingReference != session.BookingReference || accepted.Ride.BookingReference != session.BookingReference {
		t.Fatalf("reference changed across acceptance: %q %q %q", session.BookingReference, accepted.Session.BookingReference, accepted.Ride.BookingReference)
	}
}

func TestConcurrentOfferAcceptanceAssignsDriverToOneSession(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const firstPassengerID = 105
	const secondPassengerID = 106
	const driverID = 207
	fixture.seedPassenger(t, ctx, firstPassengerID)
	fixture.seedPassenger(t, ctx, secondPassengerID)
	fixture.seedDriver(t, ctx, driverID)
	firstSessionID := fixture.createBidSession(t, ctx, firstPassengerID)
	secondSessionID := fixture.createBidSession(t, ctx, secondPassengerID)
	firstOfferID := fixture.createBidOffer(t, ctx, firstSessionID, driverID)
	secondOfferID := fixture.createBidOffer(t, ctx, secondSessionID, driverID)

	start := make(chan struct{})
	results := make(chan error, 2)
	for _, offer := range []struct{ sessionID, offerID, passengerID int }{
		{firstSessionID, firstOfferID, firstPassengerID},
		{secondSessionID, secondOfferID, secondPassengerID},
	} {
		go func(sessionID, offerID, passengerID int) {
			<-start
			_, err := fixture.dispatchStore.AcceptOffer(ctx, sessionID, offerID, passengerID)
			results <- err
		}(offer.sessionID, offer.offerID, offer.passengerID)
	}
	close(start)
	firstErr := <-results
	secondErr := <-results
	if (firstErr == nil) == (secondErr == nil) {
		t.Fatalf("driver assignment attempts returned (%v, %v), want exactly one success", firstErr, secondErr)
	}
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM rides
WHERE driver_id = $1 AND status IN ('assigned', 'accepted', 'arrived', 'in_transit')`, driverID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM bid_offers
WHERE driver_id = $1 AND status = 'accepted'`, driverID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM ride_settlements AS settlement
JOIN rides ON rides.id = settlement.ride_id
WHERE rides.driver_id = $1`, driverID, 1)
}

func TestSessionCancellationRacingOfferAcceptanceHasOneCommittedOutcome(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const passengerID = 102
	const driverID = 203
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, driverID)
	sessionID := fixture.createBidSession(t, ctx, passengerID)
	offerID := fixture.createBidOffer(t, ctx, sessionID, driverID)

	start := make(chan struct{})
	type commandResult struct {
		name string
		err  error
	}
	results := make(chan commandResult, 2)
	go func() {
		<-start
		_, err := fixture.dispatchStore.AcceptOffer(ctx, sessionID, offerID, passengerID)
		results <- commandResult{name: "accept", err: err}
	}()
	go func() {
		<-start
		_, err := fixture.dispatchStore.CancelSession(ctx, sessionID, passengerID)
		results <- commandResult{name: "cancel", err: err}
	}()
	close(start)

	var acceptanceErr, cancellationErr error
	for range 2 {
		result := <-results
		if result.name == "accept" {
			acceptanceErr = result.err
		} else {
			cancellationErr = result.err
		}
	}
	if (acceptanceErr == nil) == (cancellationErr == nil) {
		t.Fatalf("acceptance and cancellation returned (%v, %v), want exactly one success", acceptanceErr, cancellationErr)
	}

	var status string
	if err := fixture.pool.QueryRow(ctx, `SELECT status FROM bid_sessions WHERE id = $1`, sessionID).Scan(&status); err != nil {
		t.Fatalf("read session status: %v", err)
	}
	switch status {
	case "accepted":
		if acceptanceErr != nil || cancellationErr == nil {
			t.Fatalf("accepted state has inconsistent command results: acceptance=%v cancellation=%v", acceptanceErr, cancellationErr)
		}
		assertRowCount(t, ctx, fixture.pool, `SELECT count(*) FROM rides WHERE passenger_id = $1`, passengerID, 1)
		assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM ride_settlements AS settlement
JOIN rides ON rides.id = settlement.ride_id
WHERE rides.passenger_id = $1`, passengerID, 1)
	case "cancelled":
		if cancellationErr != nil || acceptanceErr == nil {
			t.Fatalf("cancelled state has inconsistent command results: acceptance=%v cancellation=%v", acceptanceErr, cancellationErr)
		}
		assertRowCount(t, ctx, fixture.pool, `SELECT count(*) FROM rides WHERE passenger_id = $1`, passengerID, 0)
		assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM ride_settlements AS settlement
JOIN rides ON rides.id = settlement.ride_id
WHERE rides.passenger_id = $1`, passengerID, 0)
	default:
		t.Fatalf("session status = %q, want accepted or cancelled", status)
	}
}

func TestRideCancellationRacingWithAcceptancePreservesAtomicState(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const passengerID = 108
	const driverID = 210
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, driverID)
	rideID := fixture.createRide(t, ctx, passengerID, 0, "requested", 2000)
	service := ridelifecycle.NewLifecycleService(ridelifecycle.LifecycleDependencies{Store: fixture.store})

	start := make(chan struct{})
	type commandResult struct {
		name string
		err  error
	}
	results := make(chan commandResult, 2)
	go func() {
		<-start
		_, err := service.AcceptRide(ctx, rideID, driverID)
		results <- commandResult{name: "accept", err: err}
	}()
	go func() {
		<-start
		_, err := service.Cancel(ctx, domain.CancellationRequest{
			RideID:  rideID,
			ActorID: passengerID,
			Reason:  domain.CancellationReasonPassengerChangedMind,
		})
		results <- commandResult{name: "cancel", err: err}
	}()
	close(start)

	var acceptErr, cancelErr error
	for range 2 {
		result := <-results
		if result.name == "accept" {
			acceptErr = result.err
		} else {
			cancelErr = result.err
		}
	}

	var status string
	var assignedDriverID pgtype.Int4
	if err := fixture.pool.QueryRow(ctx, `
SELECT status, driver_id
FROM rides
WHERE id = $1`, rideID).Scan(&status, &assignedDriverID); err != nil {
		t.Fatalf("read ride state: %v", err)
	}
	var wantSettlements int
	switch status {
	case "accepted":
		if acceptErr != nil || cancelErr == nil || !errors.Is(cancelErr, pgx.ErrNoRows) {
			t.Fatalf("accepted state has inconsistent outcomes: acceptance=%v cancellation=%v", acceptErr, cancelErr)
		}
		if !assignedDriverID.Valid || assignedDriverID.Int32 != driverID {
			t.Fatalf("assigned driver = %v, want %d", assignedDriverID, driverID)
		}
		wantSettlements = 1
	case "cancelled":
		if cancelErr != nil {
			t.Fatalf("cancellation failed with cancelled state: %v", cancelErr)
		}
		if assignedDriverID.Valid {
			if assignedDriverID.Int32 != driverID || acceptErr != nil {
				t.Fatalf("cancelled accepted ride has inconsistent outcomes: driver=%v acceptance=%v", assignedDriverID, acceptErr)
			}
			wantSettlements = 1
		} else if acceptErr == nil || !errors.Is(acceptErr, pgx.ErrNoRows) {
			t.Fatalf("unassigned cancelled ride has inconsistent acceptance result: %v", acceptErr)
		}
	default:
		t.Fatalf("ride status = %q, want accepted or cancelled", status)
	}
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM ride_settlements WHERE ride_id = $1`, rideID, wantSettlements)
	wantCancellationRecords := 0
	if status == "cancelled" {
		wantCancellationRecords = 1
	}
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM ride_events WHERE ride_id = $1 AND to_status = 'cancelled'`, rideID, wantCancellationRecords)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM audit_events WHERE action = 'ride.cancelled' AND target_id = $1`, fmt.Sprint(rideID), wantCancellationRecords)
}

func TestStaleRideStateTransitionCannotOverwriteCancellation(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const passengerID = 109
	fixture.seedPassenger(t, ctx, passengerID)
	rideID := fixture.createRide(t, ctx, passengerID, 0, "requested", 2000)
	service := ridelifecycle.NewLifecycleService(ridelifecycle.LifecycleDependencies{Store: fixture.store})
	if _, err := service.Cancel(ctx, domain.CancellationRequest{
		RideID:  rideID,
		ActorID: passengerID,
		Reason:  domain.CancellationReasonPassengerChangedMind,
	}); err != nil {
		t.Fatalf("cancel requested ride: %v", err)
	}

	_, err := fixture.store.UpdateStatus(
		ctx,
		rideID,
		passengerID,
		string(domain.RideRequested),
		string(domain.RideAccepted),
		domain.RideTransition{EventType: domain.RideEventStatusChanged},
	)
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("stale transition error = %v, want no matching current-state row", err)
	}

	var status string
	if err := fixture.pool.QueryRow(ctx, `SELECT status FROM rides WHERE id = $1`, rideID).Scan(&status); err != nil {
		t.Fatalf("read ride after stale transition: %v", err)
	}
	if status != "cancelled" {
		t.Fatalf("ride status = %q, want cancelled", status)
	}
	assertRowCount(t, ctx, fixture.pool, `SELECT count(*) FROM ride_events WHERE ride_id = $1`, rideID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM audit_events WHERE action = 'ride.cancelled' AND target_id = $1`, fmt.Sprint(rideID), 1)
}

func TestConcurrentRideCompletionWritesOneLifecycleEvent(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const passengerID = 103
	const driverID = 204
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, driverID)
	rideID := fixture.createRide(t, ctx, passengerID, driverID, "in_transit", 2000)

	start := make(chan struct{})
	results := make(chan error, 2)
	var workers sync.WaitGroup
	for range 2 {
		workers.Add(1)
		go func() {
			defer workers.Done()
			<-start
			_, err := fixture.store.CompleteTrip(ctx, rideID, driverID)
			results <- err
		}()
	}
	close(start)
	workers.Wait()
	firstErr := <-results
	secondErr := <-results
	if (firstErr == nil) == (secondErr == nil) {
		t.Fatalf("ride completions returned (%v, %v), want exactly one success", firstErr, secondErr)
	}

	var status string
	if err := fixture.pool.QueryRow(ctx, `SELECT status FROM rides WHERE id = $1`, rideID).Scan(&status); err != nil {
		t.Fatalf("read completed ride: %v", err)
	}
	if status != "completed" {
		t.Fatalf("ride status = %q, want completed", status)
	}
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM ride_events WHERE ride_id = $1 AND to_status = 'completed'`, rideID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*)
FROM audit_events
WHERE action = 'ride.completed' AND target_id = $1`, fmt.Sprint(rideID), 1)
}

func TestConcurrentCashSettlementCreditsWalletOnce(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const passengerID = 104
	const driverID = 205
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, driverID)
	rideID := fixture.createRide(t, ctx, passengerID, driverID, "completed", 2000)
	if _, err := fixture.pool.Exec(ctx, `
INSERT INTO ride_settlements (
    ride_id, gross_fare, commission_bps, commission_amount, driver_payout_amount
)
VALUES ($1, 2000, 1500, 300, 1700)`, rideID); err != nil {
		t.Fatalf("create ride settlement: %v", err)
	}
	request := domain.CashSettlementRequest{
		RideID:         rideID,
		DriverID:       driverID,
		ReceivedAmount: 2000,
		Outcome:        domain.CashOutcomePaid,
	}

	start := make(chan struct{})
	results := make(chan error, 2)
	var workers sync.WaitGroup
	for range 2 {
		workers.Add(1)
		go func() {
			defer workers.Done()
			<-start
			_, err := fixture.store.SettleCash(ctx, request)
			results <- err
		}()
	}
	close(start)
	workers.Wait()
	firstErr := <-results
	secondErr := <-results
	if firstErr != nil || secondErr != nil {
		t.Fatalf("cash settlement retries returned (%v, %v), want both successful", firstErr, secondErr)
	}

	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM wallet_ledgers WHERE ride_id = $1 AND kind = 'cash_trip'`, rideID, 1)
	assertRowCount(t, ctx, fixture.pool, `
SELECT count(*) FROM audit_events WHERE action = 'ride.cash_settled' AND target_id = $1`, fmt.Sprint(rideID), 1)
	var balance int64
	if err := fixture.pool.QueryRow(ctx, `
SELECT balance FROM driver_wallet_accounts WHERE driver_id = $1`, driverID).Scan(&balance); err != nil {
		t.Fatalf("read driver wallet balance: %v", err)
	}
	if balance != 1700 {
		t.Fatalf("driver wallet balance = %d, want 1700", balance)
	}
	var paymentStatus, cashOutcome string
	if err := fixture.pool.QueryRow(ctx, `
SELECT payment_status, cash_outcome
FROM ride_settlements
WHERE ride_id = $1`, rideID).Scan(&paymentStatus, &cashOutcome); err != nil {
		t.Fatalf("read settled outcome: %v", err)
	}
	if paymentStatus != "paid" || cashOutcome != string(domain.CashOutcomePaid) {
		t.Fatalf("settlement state = (%q, %q), want paid", paymentStatus, cashOutcome)
	}
}

type postgresRideFixture struct {
	pool          *pgxpool.Pool
	store         *ridepostgres.RideRepository
	dispatchStore *dispatchpostgres.Store
}

func newPostgresRideFixture(t *testing.T) *postgresRideFixture {
	t.Helper()
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("TEST_DATABASE_URL is not set")
	}

	ctx, cancel := context.WithTimeout(t.Context(), 30*time.Second)
	defer cancel()
	admin, err := pgx.Connect(ctx, databaseURL)
	if err != nil {
		t.Fatalf("connect to test PostgreSQL database: %v", err)
	}
	schemaName := fmt.Sprintf("ride_race_it_%d", time.Now().UnixNano())
	quotedSchema := pgx.Identifier{schemaName}.Sanitize()
	if _, err := admin.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		_ = admin.Close(context.Background())
		t.Fatalf("create isolated test schema: %v", err)
	}

	var pool *pgxpool.Pool
	t.Cleanup(func() {
		if pool != nil {
			pool.Close()
		}
		cleanupContext, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		_, _ = admin.Exec(cleanupContext, "DROP SCHEMA "+quotedSchema+" CASCADE")
		_ = admin.Close(cleanupContext)
	})

	if _, err := admin.Exec(ctx, "SET search_path TO "+quotedSchema); err != nil {
		t.Fatalf("set isolated schema search path: %v", err)
	}
	for _, filename := range []string{
		"users.sql",
		"profiles.sql",
		"booking_references.sql",
		"bid_sessions.sql",
		"rides.sql",
		"bid_offers.sql",
		"ride_settlements.sql",
		"ride_events.sql",
		"ride_reports.sql",
		"driver_wallet_accounts.sql",
		"wallet_ledgers.sql",
		"audit_events.sql",
	} {
		schema, err := os.ReadFile(filepath.Join("../../../db/schema", filename))
		if err != nil {
			t.Fatalf("read canonical schema %s: %v", filename, err)
		}
		if _, err := admin.Exec(ctx, string(schema)); err != nil {
			t.Fatalf("apply canonical schema %s: %v", filename, err)
		}
	}

	poolConfig, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		t.Fatalf("parse test PostgreSQL connection: %v", err)
	}
	poolConfig.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	poolConfig.MaxConns = 8
	pool, err = pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		t.Fatalf("connect to isolated ride schema: %v", err)
	}
	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("ping isolated ride schema: %v", err)
	}
	store, err := ridepostgres.NewRideRepository(ridepostgres.RideRepositoryConfig{
		Pool:                  pool,
		PlatformCommissionBPS: 1500,
		OnlinePresenceMaxAge:  time.Minute,
	})
	if err != nil {
		t.Fatalf("create ride persistence adapter: %v", err)
	}
	dispatchStore, err := dispatchpostgres.NewStore(dispatchpostgres.StoreConfig{
		Pool:                  pool,
		PlatformCommissionBPS: 1500,
		OnlinePresenceMaxAge:  time.Minute,
	})
	if err != nil {
		t.Fatalf("create dispatch persistence adapter: %v", err)
	}
	return &postgresRideFixture{pool: pool, store: store, dispatchStore: dispatchStore}
}

func (fixture *postgresRideFixture) seedPassenger(t *testing.T, ctx context.Context, userID int) {
	t.Helper()
	fixture.seedUser(t, ctx, userID, "passenger")
}

func (fixture *postgresRideFixture) seedDriver(t *testing.T, ctx context.Context, userID int) {
	t.Helper()
	fixture.seedUser(t, ctx, userID, "driver")
	if _, err := fixture.pool.Exec(ctx, `
INSERT INTO driver_profiles (
    user_id, name, vehicle_type, plate_number, rating, is_online, online_last_seen_at
)
VALUES ($1, $2, 'motorcycle', $3, 4.8, true, CURRENT_TIMESTAMP)`,
		userID,
		fmt.Sprintf("Driver %d", userID),
		fmt.Sprintf("PLATE-%d", userID),
	); err != nil {
		t.Fatalf("seed driver profile %d: %v", userID, err)
	}
}

func (fixture *postgresRideFixture) seedUser(t *testing.T, ctx context.Context, userID int, role string) {
	t.Helper()
	if _, err := fixture.pool.Exec(ctx, `
INSERT INTO users (id, name, phone, email, password_hash, role, is_verified)
VALUES ($1, $2, $3, $4, 'test-hash', $5, true)`,
		userID,
		fmt.Sprintf("User %d", userID),
		fmt.Sprintf("phone-%d", userID),
		fmt.Sprintf("user-%d@example.test", userID),
		role,
	); err != nil {
		t.Fatalf("seed user %d: %v", userID, err)
	}
}

func (fixture *postgresRideFixture) createBidSession(t *testing.T, ctx context.Context, passengerID int) int {
	t.Helper()
	var sessionID int
	if err := fixture.pool.QueryRow(ctx, `
INSERT INTO bid_sessions (
    passenger_id, ride_type, pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name, distance_km,
    duration_minutes, offered_fare, expires_at
)
VALUES ($1, 'Solo Ride', 14.5, 121.0, 'Origin', 14.6, 121.1, 'Destination',
    2.0, 10.0, 2000, CURRENT_TIMESTAMP + interval '10 minutes')
RETURNING id`, passengerID).Scan(&sessionID); err != nil {
		t.Fatalf("create bid session: %v", err)
	}
	return sessionID
}

func (fixture *postgresRideFixture) createBidOffer(
	t *testing.T,
	ctx context.Context,
	sessionID, driverID int,
) int {
	t.Helper()
	var offerID int
	if err := fixture.pool.QueryRow(ctx, `
INSERT INTO bid_offers (session_id, driver_id, driver_name, plate_number, vehicle_type, proposed_fare)
VALUES ($1, $2, $3, $4, 'motorcycle', 2000)
RETURNING id`,
		sessionID,
		driverID,
		fmt.Sprintf("Driver %d", driverID),
		fmt.Sprintf("PLATE-%d", driverID),
	).Scan(&offerID); err != nil {
		t.Fatalf("create bid offer: %v", err)
	}
	return offerID
}

func (fixture *postgresRideFixture) createRide(
	t *testing.T,
	ctx context.Context,
	passengerID, driverID int,
	status string,
	fare int64,
) int {
	t.Helper()
	dbDriverID := pgtype.Int4{}
	if driverID > 0 {
		dbDriverID = pgtype.Int4{Int32: int32(driverID), Valid: true}
	}
	var rideID int
	if err := fixture.pool.QueryRow(ctx, `
INSERT INTO rides (
    passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number
)
VALUES ($1, $2, $3, $4, 'Solo Ride', 14.5, 121.0, 'Origin',
    14.6, 121.1, 'Destination', 2.0, 10.0, $5, 'motorcycle', $6)
RETURNING id`,
		passengerID,
		dbDriverID,
		status,
		fare,
		fmt.Sprintf("Driver %d", driverID),
		fmt.Sprintf("PLATE-%d", driverID),
	).Scan(&rideID); err != nil {
		t.Fatalf("create ride: %v", err)
	}
	return rideID
}

func assertRowCount(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	query string,
	argument any,
	want int,
) {
	t.Helper()
	var count int
	if err := pool.QueryRow(ctx, query, argument).Scan(&count); err != nil {
		t.Fatalf("count rows: %v", err)
	}
	if count != want {
		t.Fatalf("row count = %d, want %d", count, want)
	}
}

func TestListDriverRidesFiltersActiveAndTerminalTrips(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()

	const passengerID = 101
	const driverID = 201
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, driverID)

	fixture.createRide(t, ctx, passengerID, driverID, "in_transit", 2500)
	fixture.createRide(t, ctx, passengerID, driverID, "completed", 3000)
	fixture.createRide(t, ctx, passengerID, driverID, "cancelled", 1500)

	// active_only = false (History query): should only return completed and cancelled rides
	historyTrips, err := fixture.store.DriverTrips(ctx, driverID, domain.TripHistoryQuery{
		Limit:      10,
		Offset:     0,
		ActiveOnly: false,
	})
	if err != nil {
		t.Fatalf("DriverTrips(active_only=false) error: %v", err)
	}
	if len(historyTrips) != 2 {
		t.Fatalf("historyTrips len = %d, want 2", len(historyTrips))
	}
	for _, trip := range historyTrips {
		if trip.Status != "completed" && trip.Status != "cancelled" {
			t.Fatalf("unexpected non-terminal ride status in history: %s", trip.Status)
		}
	}

	// active_only = true (Active rides query): should only return active rides
	activeTrips, err := fixture.store.DriverTrips(ctx, driverID, domain.TripHistoryQuery{
		Limit:      10,
		Offset:     0,
		ActiveOnly: true,
	})
	if err != nil {
		t.Fatalf("DriverTrips(active_only=true) error: %v", err)
	}
	if len(activeTrips) != 1 {
		t.Fatalf("activeTrips len = %d, want 1", len(activeTrips))
	}
	if activeTrips[0].Status != "in_transit" {
		t.Fatalf("activeTrips[0].Status = %s, want in_transit", activeTrips[0].Status)
	}
}

func TestRideCreationRejectsPassengerWithOpenBidSession(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx := context.Background()
	passengerID := 9301
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.createBidSession(t, ctx, passengerID)

	_, err := fixture.store.CreateRide(ctx, domain.Ride{
		PassengerID: passengerID,
		Status:      string(domain.RideRequested),
		FareAmount:  2500,
	})
	if !errors.Is(err, domain.ErrActiveBooking) {
		t.Fatalf("CreateRide() error = %v, want %v", err, domain.ErrActiveBooking)
	}
	assertRowCount(t, ctx, fixture.pool, `SELECT count(*) FROM rides WHERE passenger_id = $1`, passengerID, 0)
}

func TestReplayAcceptedOfferReturnsOriginalRideNotUnrelatedRide(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx := context.Background()
	passengerID := 9401
	driverID := 9402
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, driverID)

	// 1. Passenger accepts driver's offer in session 1 -> creates ride 1.
	session1ID := fixture.createBidSession(t, ctx, passengerID)
	offer1ID := fixture.createBidOffer(t, ctx, session1ID, driverID)

	acceptance1, err := fixture.dispatchStore.AcceptOffer(ctx, session1ID, offer1ID, passengerID)
	if err != nil {
		t.Fatalf("first AcceptOffer() error = %v", err)
	}
	ride1ID := acceptance1.Ride.ID

	// Verify replay while R1 is active returns R1.
	replayActive, err := fixture.dispatchStore.AcceptOffer(ctx, session1ID, offer1ID, passengerID)
	if err != nil {
		t.Fatalf("replay AcceptOffer() while R1 active error = %v", err)
	}
	if replayActive.Ride.ID != ride1ID {
		t.Fatalf("replayed ride ID = %d, want original ride %d", replayActive.Ride.ID, ride1ID)
	}

	// 2. Complete R1.
	if _, err := fixture.pool.Exec(ctx, `UPDATE rides SET status = 'completed', completed_at = CURRENT_TIMESTAMP WHERE id = $1`, ride1ID); err != nil {
		t.Fatalf("complete ride 1: %v", err)
	}

	// 3. Passenger and driver create another active ride R2 through a second session.
	session2ID := fixture.createBidSession(t, ctx, passengerID)
	offer2ID := fixture.createBidOffer(t, ctx, session2ID, driverID)

	acceptance2, err := fixture.dispatchStore.AcceptOffer(ctx, session2ID, offer2ID, passengerID)
	if err != nil {
		t.Fatalf("second AcceptOffer() error = %v", err)
	}
	ride2ID := acceptance2.Ride.ID
	if ride2ID == ride1ID {
		t.Fatalf("second ride ID = %d, want different from ride 1 %d", ride2ID, ride1ID)
	}

	// 4. Replay AcceptOffer for session 1 / offer 1 while R2 is active.
	replayCompleted, err := fixture.dispatchStore.AcceptOffer(ctx, session1ID, offer1ID, passengerID)
	if err != nil {
		t.Fatalf("replay AcceptOffer() for completed R1 error = %v", err)
	}
	if replayCompleted.Ride.ID != ride1ID {
		t.Fatalf("replayed ride ID = %d, want %d (must NOT return unrelated current ride %d)", replayCompleted.Ride.ID, ride1ID, ride2ID)
	}
}

func TestAcceptedRideCapturesDriverRatingSnapshot(t *testing.T) {
	fixture := newPostgresRideFixture(t)
	ctx := context.Background()
	passengerID := 9501
	driverID := 9502
	fixture.seedPassenger(t, ctx, passengerID)
	fixture.seedDriver(t, ctx, driverID) // rating seeded as 4.8

	// Path 1: Bid session acceptance captures driver rating snapshot.
	sessionID := fixture.createBidSession(t, ctx, passengerID)
	offerID := fixture.createBidOffer(t, ctx, sessionID, driverID)

	acceptance, err := fixture.dispatchStore.AcceptOffer(ctx, sessionID, offerID, passengerID)
	if err != nil {
		t.Fatalf("AcceptOffer() error = %v", err)
	}
	if acceptance.Ride.DriverRating != 4.8 {
		t.Fatalf("acceptance.Ride.DriverRating = %f, want 4.8", acceptance.Ride.DriverRating)
	}

	var storedRating float64
	if err := fixture.pool.QueryRow(ctx, `SELECT driver_rating FROM rides WHERE id = $1`, acceptance.Ride.ID).Scan(&storedRating); err != nil {
		t.Fatalf("read stored driver rating: %v", err)
	}
	if storedRating != 4.8 {
		t.Fatalf("stored driver_rating in rides = %f, want 4.8", storedRating)
	}

	// Update driver's rating in profile (e.g. subsequent review changes profile to 3.5).
	if _, err := fixture.pool.Exec(ctx, `UPDATE driver_profiles SET rating = 3.5 WHERE user_id = $1`, driverID); err != nil {
		t.Fatalf("update driver rating in profile: %v", err)
	}

	// Stored historical snapshot must remain 4.8.
	if err := fixture.pool.QueryRow(ctx, `SELECT driver_rating FROM rides WHERE id = $1`, acceptance.Ride.ID).Scan(&storedRating); err != nil {
		t.Fatalf("re-read stored driver rating: %v", err)
	}
	if storedRating != 4.8 {
		t.Fatalf("stored driver_rating changed to %f, want immutable 4.8", storedRating)
	}

	// Complete the ride.
	if _, err := fixture.pool.Exec(ctx, `UPDATE rides SET status = 'completed', completed_at = CURRENT_TIMESTAMP WHERE id = $1`, acceptance.Ride.ID); err != nil {
		t.Fatalf("complete ride: %v", err)
	}

	// Path 2: Direct ride acceptance also captures current driver rating snapshot (3.5).
	tripID := fixture.createRide(t, ctx, passengerID, 0, string(domain.RideRequested), 3000)
	acceptedTrip, err := fixture.store.AcceptRide(ctx, tripID, driverID)
	if err != nil {
		t.Fatalf("AcceptRide() error = %v", err)
	}
	if acceptedTrip.DriverRating != 3.5 {
		t.Fatalf("acceptedTrip.DriverRating = %f, want 3.5", acceptedTrip.DriverRating)
	}
	if err := fixture.pool.QueryRow(ctx, `SELECT driver_rating FROM rides WHERE id = $1`, tripID).Scan(&storedRating); err != nil {
		t.Fatalf("read direct ride driver_rating: %v", err)
	}
	if storedRating != 3.5 {
		t.Fatalf("stored direct ride driver_rating = %f, want 3.5", storedRating)
	}
}
