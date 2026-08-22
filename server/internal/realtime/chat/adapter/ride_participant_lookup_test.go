package adapter

import (
	"context"
	"errors"
	"testing"

	ridesdomain "github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type rideReaderStub struct {
	ride ridesdomain.Ride
	err  error
}

func (stub rideReaderStub) Get(context.Context, int) (ridesdomain.Ride, error) {
	return stub.ride, stub.err
}

func TestRideParticipantLookupReadsAuthoritativeParticipants(t *testing.T) {
	driverID := 8
	lookup := NewRideParticipantLookup(rideReaderStub{
		ride: ridesdomain.Ride{ID: 42, PassengerID: 7, DriverID: &driverID},
	})

	assignment, found, err := lookup.ForRide(context.Background(), "42")
	if err != nil {
		t.Fatalf("lookup error = %v", err)
	}
	if !found {
		t.Fatal("lookup did not find the ride participants")
	}
	if assignment.RideID != "42" || assignment.PassengerID != "7" || assignment.DriverID != "8" {
		t.Fatalf("assignment = %#v", assignment)
	}
}

func TestRideParticipantLookupTreatsInvalidRideAsMissing(t *testing.T) {
	lookup := NewRideParticipantLookup(rideReaderStub{})

	_, found, err := lookup.ForRide(context.Background(), "not-a-ride")
	if err != nil {
		t.Fatalf("lookup error = %v", err)
	}
	if found {
		t.Fatal("invalid ride was reported as found")
	}
}

func TestRideParticipantLookupReturnsRepositoryFailures(t *testing.T) {
	lookup := NewRideParticipantLookup(rideReaderStub{err: errors.New("database unavailable")})

	_, found, err := lookup.ForRide(context.Background(), "42")
	if err == nil || found {
		t.Fatalf("found = %t, err = %v; want repository failure", found, err)
	}
}
