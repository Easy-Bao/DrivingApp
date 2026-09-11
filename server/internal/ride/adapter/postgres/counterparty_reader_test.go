package postgres

import (
	"errors"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

func TestCounterpartyIdentityFromNativeRideUsesOptionalDriver(t *testing.T) {
	ride := domain.Ride{ID: 303, PassengerID: 99, DriverID: intPointer(42)}

	targetID, role, err := counterpartyIdentityFromRide(ride, 99)
	if err != nil || targetID != 42 || role != "driver" {
		t.Fatalf("passenger target = %d/%s, error = %v", targetID, role, err)
	}
	targetID, role, err = counterpartyIdentityFromRide(ride, 42)
	if err != nil || targetID != 99 || role != "passenger" {
		t.Fatalf("driver target = %d/%s, error = %v", targetID, role, err)
	}
	unassignedRide := domain.Ride{PassengerID: 99}
	_, _, err = counterpartyIdentityFromRide(unassignedRide, 99)
	if !errors.Is(err, domain.ErrCounterpartyUnavailable) {
		t.Fatalf("unassigned passenger error = %v", err)
	}
}

func TestNativeRideContactAvailabilityHandlesCompletedTimestamp(t *testing.T) {
	completedAt := time.Now().Add(-time.Hour).UTC().Format(time.RFC3339)
	active, until := rideContactAvailabilityFromRide(domain.Ride{Status: "completed", CompletedAt: &completedAt})
	if !active || until == nil {
		t.Fatalf("recent native ride availability = %t/%v", active, until)
	}
	invalid := "not-a-timestamp"
	active, until = rideContactAvailabilityFromRide(domain.Ride{Status: "completed", CompletedAt: &invalid})
	if active || until != nil {
		t.Fatalf("invalid native ride availability = %t/%v", active, until)
	}
}

func intPointer(value int) *int {
	return &value
}
