package adapter

import (
	"errors"
	"fmt"
	"testing"
	"time"

	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5"
)

func TestCompletedRideCommunicationWindow(t *testing.T) {
	driverID := 42
	recent := time.Now().Add(-time.Hour).UTC().Format(time.RFC3339)
	expired := time.Now().Add(-49 * time.Hour).UTC().Format(time.RFC3339)

	recentAssignment, found := fromRide(ridedomain.Ride{
		ID: 303, PassengerID: 99, DriverID: &driverID, Status: "completed", CompletedAt: &recent,
	})
	if !found || !recentAssignment.AllowsCommunication() {
		t.Fatalf("recent assignment = %#v, found = %t", recentAssignment, found)
	}

	expiredAssignment, found := fromRide(ridedomain.Ride{
		ID: 304, PassengerID: 99, DriverID: &driverID, Status: "completed", CompletedAt: &expired,
	})
	if !found || expiredAssignment.AllowsCommunication() {
		t.Fatalf("expired assignment = %#v, found = %t", expiredAssignment, found)
	}
}

func TestIsRideNotFoundRecognizesNativeDatabaseErrors(t *testing.T) {
	if !isRideNotFound(fmt.Errorf("load ride: %w", pgx.ErrNoRows)) {
		t.Fatal("expected wrapped PostgreSQL no-rows error to be classified as not found")
	}
	if isRideNotFound(errors.New("ride query failed")) {
		t.Fatal("unexpected not-found classification for unrelated error")
	}
}
