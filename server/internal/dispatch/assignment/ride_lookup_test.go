package assignment

import (
	"errors"
	"fmt"
	"testing"
	"time"

	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5"
)

func TestCompletedRideCommunicationWindow(t *testing.T) {
	tests := []struct {
		name string
		age  time.Duration
		want bool
	}{
		{name: "inside contact window", age: 23 * time.Hour, want: true},
		{name: "outside contact window", age: 25 * time.Hour, want: false},
		{name: "future completion", age: -time.Hour, want: false},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			driverID := 42
			completedAt := time.Now().Add(-test.age).UTC().Format(time.RFC3339)
			ride := ridedomain.Ride{
				ID: 303, PassengerID: 99, DriverID: &driverID,
				Status: "completed", CompletedAt: &completedAt,
			}
			got, found := fromRide(ride)
			if !found || got.AllowsCommunication() != test.want {
				t.Fatalf("assignment = %#v, found = %t, want communication %t", got, found, test.want)
			}
		})
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
