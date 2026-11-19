package app

import (
	"context"
	"errors"
	"testing"
	"time"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

type lookupStub struct {
	byRide         Assignment
	ridesByDriver  []Assignment
	err            error
	forRideCalls   *int
	forDriverCalls *int
}

func newTestResolver(routing, authority Lookup) *Resolver {
	return NewResolver(ResolverDependencies{Routing: routing, Authority: authority})
}

func (stub lookupStub) ForRide(context.Context, string) (Assignment, bool, error) {
	if stub.forRideCalls != nil {
		*stub.forRideCalls++
	}
	return stub.byRide, stub.byRide.RideID != "", stub.err
}

func (stub lookupStub) ForDriver(context.Context, string) ([]Assignment, error) {
	if stub.forDriverCalls != nil {
		*stub.forDriverCalls++
	}
	return stub.ridesByDriver, stub.err
}

func TestResolverUsesRoutingProjectionForRideAuthorization(t *testing.T) {
	authorityCalls := 0
	routing := lookupStub{byRide: Assignment{RideID: "303", DriverID: "42", PassengerID: "99", Status: "assigned"}}
	authority := lookupStub{
		byRide:       Assignment{RideID: "303", DriverID: "wrong", PassengerID: "wrong", Status: "assigned"},
		forRideCalls: &authorityCalls,
	}

	value, found, err := newTestResolver(routing, authority).ForRide(context.Background(), "303")

	if err != nil || !found {
		t.Fatalf("ForRide() found = %t, error = %v", found, err)
	}
	if value.DriverID != "42" || value.PassengerID != "99" {
		t.Fatalf("ForRide() = %#v", value)
	}
	if authorityCalls != 0 {
		t.Fatalf("authority ForRide() calls = %d, want 0", authorityCalls)
	}
}

func TestResolverFallsBackToAuthorityWhenRideProjectionMisses(t *testing.T) {
	authorityCalls := 0
	authority := lookupStub{
		byRide:       Assignment{RideID: "303", DriverID: "42", PassengerID: "99", Status: "assigned"},
		forRideCalls: &authorityCalls,
	}

	value, found, err := newTestResolver(lookupStub{}, authority).ForRide(context.Background(), "303")

	if err != nil || !found {
		t.Fatalf("ForRide() found = %t, error = %v", found, err)
	}
	if value.DriverID != "42" || value.PassengerID != "99" {
		t.Fatalf("ForRide() = %#v", value)
	}
	if authorityCalls != 1 {
		t.Fatalf("authority ForRide() calls = %d, want 1", authorityCalls)
	}
}

func TestResolverFallsBackToAuthorityWhenRoutingCacheMisses(t *testing.T) {
	authoritative := []Assignment{
		{RideID: "303", DriverID: "42", PassengerID: "99", Status: "assigned"},
		{RideID: "304", DriverID: "42", PassengerID: "100", Status: "in_transit"},
	}
	resolver := newTestResolver(lookupStub{}, lookupStub{ridesByDriver: authoritative})

	values, err := resolver.ForDriver(context.Background(), "42")

	if err != nil {
		t.Fatal(err)
	}
	if len(values) != 2 {
		t.Fatalf("ForDriver() returned %d assignments", len(values))
	}
	values[0].Status = "mutated"
	if authoritative[0].Status != "assigned" {
		t.Fatalf("authority assignments were mutated through resolver result: %#v", authoritative)
	}
}

func TestResolverFallsBackAfterRoutingCacheFailure(t *testing.T) {
	authoritative := []Assignment{{RideID: "303", DriverID: "42"}}
	resolver := newTestResolver(
		lookupStub{err: errors.New("cache unavailable")},
		lookupStub{ridesByDriver: authoritative},
	)

	values, err := resolver.ForDriver(context.Background(), "42")

	if err != nil || len(values) != 1 || values[0].RideID != "303" {
		t.Fatalf("ForDriver() = %#v, %v", values, err)
	}
}

func TestResolverStopsFallbackWhenRideContextIsCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	authorityCalls := 0
	authority := lookupStub{
		byRide:       Assignment{RideID: "303", DriverID: "42", PassengerID: "99"},
		forRideCalls: &authorityCalls,
	}

	_, found, err := newTestResolver(lookupStub{}, authority).ForRide(ctx, "303")

	if !errors.Is(err, context.Canceled) || found {
		t.Fatalf("ForRide() found = %t, error = %v; want canceled", found, err)
	}
	if authorityCalls != 0 {
		t.Fatalf("authority ForRide() calls = %d, want 0", authorityCalls)
	}
}

func TestResolverStopsDriverFallbackWhenContextIsCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	authority := lookupStub{ridesByDriver: []Assignment{{RideID: "303"}}}

	values, err := newTestResolver(lookupStub{}, authority).ForDriver(ctx, "42")

	if !errors.Is(err, context.Canceled) || values != nil {
		t.Fatalf("ForDriver() = %#v, %v; want canceled", values, err)
	}
}

func TestResolverStopsAfterRoutingCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	authorityCalls := 0
	authority := lookupStub{
		byRide:       Assignment{RideID: "303", DriverID: "42", PassengerID: "99"},
		forRideCalls: &authorityCalls,
	}
	routing := cancelingLookup{cancel: cancel}

	_, found, err := newTestResolver(routing, authority).ForRide(ctx, "303")

	if !errors.Is(err, context.Canceled) || found {
		t.Fatalf("ForRide() found = %t, error = %v; want canceled", found, err)
	}
	if authorityCalls != 0 {
		t.Fatalf("authority ForRide() calls = %d, want 0", authorityCalls)
	}
}

type cancelingLookup struct {
	cancel context.CancelFunc
}

func (lookup cancelingLookup) ForRide(context.Context, string) (Assignment, bool, error) {
	lookup.cancel()
	return Assignment{}, false, context.Canceled
}

func (cancelingLookup) ForDriver(context.Context, string) ([]Assignment, error) {
	return nil, context.Canceled
}

func TestResolverForRideDoesNotWipeActiveRidesOrCacheTerminalRides(t *testing.T) {
	projection := NewMemoryProjection()
	projection.Remember("42", []Assignment{
		{RideID: "303", DriverID: "42", PassengerID: "99", Status: "accepted"},
		{RideID: "304", DriverID: "42", PassengerID: "100", Status: "in_transit"},
	})
	completedAt := time.Now().Add(-time.Hour)
	authorityCalls := 0
	authority := lookupStub{
		byRide: Assignment{
			RideID:      "100",
			DriverID:    "42",
			PassengerID: "55",
			Status:      "completed",
			ContactOpen: true,
			CompletedAt: &completedAt,
		},
		forRideCalls: &authorityCalls,
	}
	resolver := newTestResolver(projection, authority)

	got, found, err := resolver.ForRide(context.Background(), "100")
	if err != nil || !found || got.Status != "completed" || !got.AllowsCommunication() {
		t.Fatalf("ForRide(100) = (%#v, %t, %v)", got, found, err)
	}

	// Completed ride must NOT be cached in the active projection.
	if _, cached, err := projection.ForRide(context.Background(), "100"); err != nil || cached {
		t.Fatalf("completed ride leaked into projection: cached=%t, err=%v", cached, err)
	}

	// Driver 42's active rides must remain intact.
	active, err := projection.ForDriver(context.Background(), "42")
	if err != nil || len(active) != 2 {
		t.Fatalf("driver active rides after ForRide = %#v, %v; want 2 active rides preserved", active, err)
	}
}

func TestResolverCachesIdleDriverAndInvalidatesOnRideMatched(t *testing.T) {
	now := time.Date(2026, time.January, 1, 0, 0, 0, 0, time.UTC)
	projection := NewMemoryProjection()
	projection.now = func() time.Time { return now }
	driverCalls := 0
	authority := lookupStub{
		ridesByDriver:  nil,
		forDriverCalls: &driverCalls,
	}
	resolver := newTestResolver(projection, authority)

	// First lookup hits authority and remembers the idle state.
	got, err := resolver.ForDriver(context.Background(), "55")
	if err != nil || len(got) != 0 || driverCalls != 1 {
		t.Fatalf("first ForDriver = (%#v, %v), calls=%d", got, err, driverCalls)
	}

	// Second lookup within TTL hits the negative cache (no authority query).
	now = now.Add(5 * time.Second)
	got, err = resolver.ForDriver(context.Background(), "55")
	if err != nil || len(got) != 0 || driverCalls != 1 {
		t.Fatalf("cached idle ForDriver = (%#v, %v), calls=%d, want 1", got, err, driverCalls)
	}

	// Matching a ride immediately invalidates the idle cache.
	matched, err := event.New(
		"match-1",
		event.RideMatched,
		now,
		event.Scope{RideID: "777", DriverID: "55", PassengerID: "88"},
		map[string]any{"ride": map[string]any{"status": "accepted"}},
	)
	if err != nil {
		t.Fatal(err)
	}
	projection.Publish(matched)

	got, err = resolver.ForDriver(context.Background(), "55")
	if err != nil || len(got) != 1 || got[0].RideID != "777" || driverCalls != 1 {
		t.Fatalf("ForDriver after match = (%#v, %v), calls=%d", got, err, driverCalls)
	}
}
