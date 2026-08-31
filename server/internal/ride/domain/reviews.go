package domain

import "context"

type Review struct {
	ID            int     `json:"id"`
	RideID        int     `json:"ride_id"`
	DriverID      int     `json:"driver_id"`
	PassengerID   int     `json:"passenger_id"`
	PassengerName string  `json:"passenger_name,omitempty"`
	Rating        float64 `json:"rating"`
	Comment       string  `json:"comment,omitempty"`
	CreatedAt     string  `json:"created_at"`
}

type PassengerReview struct {
	ID          int     `json:"id"`
	RideID      int     `json:"ride_id"`
	DriverID    int     `json:"driver_id"`
	PassengerID int     `json:"passenger_id"`
	Rating      float64 `json:"rating"`
	Comment     string  `json:"comment,omitempty"`
	CreatedAt   string  `json:"created_at"`
}

type ReviewRepository interface {
	DriverReviews(ctx context.Context, driverID int, limit, offset int) ([]Review, error)
	CreateReview(ctx context.Context, review Review) (Review, error)
}

type PassengerReviewRepository interface {
	CreatePassengerReview(ctx context.Context, review PassengerReview) (PassengerReview, error)
}
