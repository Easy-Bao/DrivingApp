package domain

import (
	"errors"
	"math"
)

var (
	ErrReviewNotAllowed = errors.New("reviews are allowed only after a completed ride")
	ErrInvalidRating    = errors.New("rating must be between 1 and 5")
	ErrReviewNotFound   = errors.New("passenger review not found")
)

type Review struct {
	ID            int
	RideID        int
	DriverID      int
	PassengerID   int
	PassengerName string
	Rating        float64
	Comment       string
	CreatedAt     string
}

type PassengerReview struct {
	ID          int
	RideID      int
	DriverID    int
	PassengerID int
	Rating      float64
	Comment     string
	CreatedAt   string
}

type ReviewableRide struct {
	Status      string
	PassengerID int
	DriverID    *int
}

func (ride ReviewableRide) AllowsReview(passengerID, driverID int) bool {
	return ride.Status == "completed" &&
		ride.PassengerID == passengerID &&
		ride.DriverID != nil &&
		*ride.DriverID == driverID
}

func ValidateRating(rating float64) error {
	if math.IsNaN(rating) || math.IsInf(rating, 0) || rating < 1 || rating > 5 {
		return ErrInvalidRating
	}
	return nil
}
