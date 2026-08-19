package domain

import "context"

type DriverStats struct {
	DriverID       int     `json:"driver_id"`
	TotalTrips     int     `json:"total_trips"`
	CompletedTrips int     `json:"completed_trips"`
	ActiveTrips    int     `json:"active_trips"`
	TotalFare      int64   `json:"total_fare_centavos"`
	AverageRating  float64 `json:"average_rating"`
}

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

type OnlineDriver struct {
	ID                    int     `json:"id"`
	UserID                int     `json:"user_id"`
	Name                  string  `json:"name"`
	VehicleType           string  `json:"vehicle_type"`
	PlateNumber           string  `json:"plate_number"`
	Rating                float64 `json:"rating"`
	OnboardPassengerCount int     `json:"onboard_passenger_count"`
	RecentFeedback        string  `json:"recent_feedback,omitempty"`
}

type PublicDriverSummary struct {
	ID          int     `json:"id"`
	Name        string  `json:"name"`
	VehicleType string  `json:"vehicle_type"`
	Rating      float64 `json:"rating"`
}

type AnalyticsRepository interface {
	DriverStats(ctx context.Context, driverID int) (DriverStats, error)
	DriverTrips(ctx context.Context, driverID int) ([]Ride, error)
	PassengerRides(ctx context.Context, passengerID int) ([]Ride, error)
	DriverReviews(ctx context.Context, driverID int, limit, offset int) ([]Review, error)
	CreateReview(ctx context.Context, review Review) (Review, error)
	OnlineDrivers(ctx context.Context) ([]OnlineDriver, error)
}

type RecentPassengerRidesRepository interface {
	PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]Ride, error)
}

type PassengerReviewRepository interface {
	CreatePassengerReview(ctx context.Context, review PassengerReview) (PassengerReview, error)
}
