package domain

import (
	"context"
	"time"
)

type PassengerActivitySummary struct {
	ThisWeekFareCentavos   int64 `json:"this_week_fare_centavos"`
	ThisWeekCompletedRides int   `json:"this_week_completed_rides"`
}

type PassengerActivitySummaryRepository interface {
	PassengerActivitySummary(ctx context.Context, passengerID int, weekStart, weekEnd time.Time) (PassengerActivitySummary, error)
}
