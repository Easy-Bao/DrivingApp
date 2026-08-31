package postgres

import (
	"errors"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

func TestCounterpartyIdentityComesFromRideParticipants(t *testing.T) {
	ride := &ent.Ride{ID: 303, PassengerID: 99, DriverID: 42}

	targetID, role, err := counterpartyIdentity(ride, 99)
	if err != nil || targetID != 42 || role != "driver" {
		t.Fatalf("passenger target = %d/%s, error = %v", targetID, role, err)
	}
	targetID, role, err = counterpartyIdentity(ride, 42)
	if err != nil || targetID != 99 || role != "passenger" {
		t.Fatalf("driver target = %d/%s, error = %v", targetID, role, err)
	}
	if _, _, err := counterpartyIdentity(ride, 7); !errors.Is(err, domain.ErrUnauthorizedRide) {
		t.Fatalf("outsider error = %v", err)
	}
}

func TestRideContactAvailabilityExpiresCompletedRides(t *testing.T) {
	active, until := rideContactAvailability(&ent.Ride{Status: "assigned"})
	if !active || until != nil {
		t.Fatalf("active ride availability = %t/%v", active, until)
	}

	recent, recentUntil := rideContactAvailability(&ent.Ride{
		Status: "completed", CompletedAt: time.Now().Add(-time.Hour),
	})
	if !recent || recentUntil == nil {
		t.Fatalf("recent ride availability = %t/%v", recent, recentUntil)
	}

	expired, _ := rideContactAvailability(&ent.Ride{
		Status: "completed", CompletedAt: time.Now().Add(-49 * time.Hour),
	})
	if expired {
		t.Fatal("expired ride still permits contact")
	}
}
