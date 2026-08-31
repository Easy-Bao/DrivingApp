package domain

import "context"

type OnlineDriver struct {
	ID                    int     `json:"id"`
	UserID                int     `json:"user_id"`
	Name                  string  `json:"name"`
	VehicleType           string  `json:"vehicle_type"`
	PlateNumber           string  `json:"plate_number"`
	Rating                float64 `json:"rating"`
	OnboardPassengerCount int     `json:"onboard_passenger_count"`
}

type PublicDriverSummary struct {
	ID          int     `json:"id"`
	Name        string  `json:"name"`
	VehicleType string  `json:"vehicle_type"`
	Rating      float64 `json:"rating"`
}

type DriverAvailabilityRepository interface {
	OnlineDrivers(ctx context.Context, driverIDs []int) ([]OnlineDriver, error)
	PublicDriverSummaries(ctx context.Context, limit int) ([]PublicDriverSummary, error)
}
