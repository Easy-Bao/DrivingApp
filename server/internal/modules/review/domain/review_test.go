package domain

import (
	"errors"
	"math"
	"testing"
)

func TestReviewableRideRequiresCompletionAndBothParticipants(t *testing.T) {
	driverID := 9
	ride := ReviewableRide{Status: "completed", PassengerID: 4, DriverID: &driverID}
	if !ride.AllowsReview(4, 9) {
		t.Fatal("completed ride participants should be allowed to review")
	}
	for _, participant := range [][2]int{{5, 9}, {4, 8}} {
		if ride.AllowsReview(participant[0], participant[1]) {
			t.Fatalf("unexpected review access for passenger=%d driver=%d", participant[0], participant[1])
		}
	}
	ride.Status = "cancelled"
	if ride.AllowsReview(4, 9) {
		t.Fatal("cancelled rides should not be reviewable")
	}
}

func TestValidateRatingRejectsOutOfRangeAndNonFiniteValues(t *testing.T) {
	for _, rating := range []float64{0, 6, math.NaN(), math.Inf(1), math.Inf(-1)} {
		if err := ValidateRating(rating); !errors.Is(err, ErrInvalidRating) {
			t.Errorf("ValidateRating(%v) error = %v, want ErrInvalidRating", rating, err)
		}
	}
	for _, rating := range []float64{1, 3.5, 5} {
		if err := ValidateRating(rating); err != nil {
			t.Errorf("ValidateRating(%v) error = %v", rating, err)
		}
	}
}
