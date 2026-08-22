package postgres

import (
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
)

func TestRideCompletionTimeFallsBackToCreationTime(t *testing.T) {
	createdAt := time.Date(2026, time.August, 22, 4, 30, 0, 0, time.UTC)
	ride := &ent.Ride{CreatedAt: createdAt}

	if got := rideCompletionTime(ride); !got.Equal(createdAt) {
		t.Fatalf("completion time = %v, want creation time %v", got, createdAt)
	}
}

func TestRideCompletionTimePrefersCompletionTime(t *testing.T) {
	createdAt := time.Date(2026, time.August, 22, 4, 30, 0, 0, time.UTC)
	completedAt := createdAt.Add(15 * time.Minute)
	ride := &ent.Ride{CreatedAt: createdAt, CompletedAt: completedAt}

	if got := rideCompletionTime(ride); !got.Equal(completedAt) {
		t.Fatalf("completion time = %v, want completed time %v", got, completedAt)
	}
}
