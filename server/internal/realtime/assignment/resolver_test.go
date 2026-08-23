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
}

func (stub lookupStub) ForRide(context.Context, string) (Assignment, bool, error) {
	return stub.byRide, stub.byRide.RideID != "", stub.err
}

func (stub lookupStub) ForDriver(context.Context, string) ([]Assignment, error) {
	return stub.ridesByDriver, stub.err
}

func TestResolverUsesAuthorityForRideAuthorization(t *testing.T) {
	routing := lookupStub{byRide: Assignment{RideID: "303", DriverID: "wrong"}}
	authority := lookupStub{byRide: Assignment{RideID: "303", DriverID: "42", PassengerID: "99"}}

	value, found, err := NewResolver(routing, authority).ForRide(context.Background(), "303")

	if err != nil || !found {
		t.Fatalf("ForRide() found = %t, error = %v", found, err)
	}
	if value.DriverID != "42" || value.PassengerID != "99" {
		t.Fatalf("ForRide() = %#v", value)
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
