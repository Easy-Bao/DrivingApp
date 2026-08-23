package adapter

import (
	"testing"
	"time"

	ridesdomain "github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

func TestCompletedRideCommunicationWindow(t *testing.T) {
	driverID := 42
	recent := time.Now().Add(-time.Hour).UTC().Format(time.RFC3339)
	expired := time.Now().Add(-49 * time.Hour).UTC().Format(time.RFC3339)

	recentAssignment, found := fromRide(ridesdomain.Ride{
		ID: 303, PassengerID: 99, DriverID: &driverID, Status: "completed", CompletedAt: &recent,
	})
	if !found || !recentAssignment.AllowsCommunication() {
		t.Fatalf("recent assignment = %#v, found = %t", recentAssignment, found)
	}

	expiredAssignment, found := fromRide(ridesdomain.Ride{
		ID: 304, PassengerID: 99, DriverID: &driverID, Status: "completed", CompletedAt: &expired,
	})
	if !found || expiredAssignment.AllowsCommunication() {
		t.Fatalf("expired assignment = %#v, found = %t", expiredAssignment, found)
	}
}
