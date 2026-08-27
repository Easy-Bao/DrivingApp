package assignment

import (
	"context"
	"errors"
	"testing"
)

type lookupStub struct {
	byRide        Assignment
	ridesByDriver []Assignment
	err           error
	forRideCalls  *int
}

func (stub lookupStub) ForRide(context.Context, string) (Assignment, bool, error) {
	if stub.forRideCalls != nil {
		*stub.forRideCalls++
	}
	return stub.byRide, stub.byRide.RideID != "", stub.err
}

func (stub lookupStub) ForDriver(context.Context, string) ([]Assignment, error) {
	return stub.ridesByDriver, stub.err
}

func TestResolverUsesRoutingProjectionForRideAuthorization(t *testing.T) {
	authorityCalls := 0
	routing := lookupStub{byRide: Assignment{RideID: "303", DriverID: "42", PassengerID: "99", Status: "assigned"}}
	authority := lookupStub{
		byRide:       Assignment{RideID: "303", DriverID: "wrong", PassengerID: "wrong", Status: "assigned"},
		forRideCalls: &authorityCalls,
	}

	value, found, err := NewResolver(routing, authority).ForRide(context.Background(), "303")

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

	value, found, err := NewResolver(lookupStub{}, authority).ForRide(context.Background(), "303")

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
	resolver := NewResolver(lookupStub{}, lookupStub{ridesByDriver: authoritative})

	values, err := resolver.ForDriver(context.Background(), "42")

	if err != nil {
		t.Fatal(err)
	}
	if len(values) != 2 {
		t.Fatalf("ForDriver() returned %d assignments", len(values))
	}
}

func TestResolverFallsBackAfterRoutingCacheFailure(t *testing.T) {
	authoritative := []Assignment{{RideID: "303", DriverID: "42"}}
	resolver := NewResolver(
		lookupStub{err: errors.New("cache unavailable")},
		lookupStub{ridesByDriver: authoritative},
	)

	values, err := resolver.ForDriver(context.Background(), "42")

	if err != nil || len(values) != 1 || values[0].RideID != "303" {
		t.Fatalf("ForDriver() = %#v, %v", values, err)
	}
}
