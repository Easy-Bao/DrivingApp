package domain

import (
	"context"
	"time"
)

type DriverStats struct {
	DriverID            int     `json:"driver_id"`
	TotalTrips          int     `json:"total_trips"`
	CompletedTrips      int     `json:"completed_trips"`
	ActiveTrips         int     `json:"active_trips"`
	TotalEarnings       int64   `json:"total_earnings_centavos"`
	TodayCompletedTrips int     `json:"today_completed_trips"`
	TodayEarnings       int64   `json:"today_earnings_centavos"`
	AverageRating       float64 `json:"average_rating"`
}

type DriverStatisticsRepository interface {
	DriverStats(ctx context.Context, driverID int, dayStart, dayEnd time.Time) (DriverStats, error)
}
