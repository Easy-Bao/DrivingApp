package app

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
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

func TestIsRideNotFoundRecognizesDomainError(t *testing.T) {
	if !isRideNotFound(fmt.Errorf("load ride: %w", ridedomain.ErrRideNotFound)) {
		t.Fatal("expected wrapped domain error to be classified as not found")
	}
	if isRideNotFound(errors.New("ride query failed")) {
		t.Fatal("unexpected not-found classification for unrelated error")
	}
}

type failingRideAuthority struct{ err error }

func (authority failingRideAuthority) Get(context.Context, int) (ridedomain.Ride, error) {
	return ridedomain.Ride{}, authority.err
}

func (authority failingRideAuthority) ActiveRidesForDriver(context.Context, int) ([]ridedomain.Ride, error) {
	return nil, authority.err
}

func TestRideLookupMissingRideErrors(t *testing.T) {
	for _, test := range []struct {
		name    string
		err     error
		missing bool
	}{
		{name: "domain missing ride", err: ridedomain.ErrRideNotFound, missing: true},
		{name: "wrapped domain missing ride", err: fmt.Errorf("find ride: %w", ridedomain.ErrRideNotFound), missing: true},
		{name: "storage failure", err: errors.New("storage unavailable")},
	} {
		t.Run(test.name, func(t *testing.T) {
			_, found, err := NewRideLookup(failingRideAuthority{err: test.err}).ForRide(context.Background(), "303")
			if found {
				t.Fatal("failed lookup must not return an assignment")
			}
			if test.missing {
				if err != nil {
					t.Fatalf("missing ride returned error: %v", err)
				}
			} else if !errors.Is(err, test.err) {
				t.Fatalf("lookup error=%v, want wrapped %v", err, test.err)
			}
		})
	}
}
