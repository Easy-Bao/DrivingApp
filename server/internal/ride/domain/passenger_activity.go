package domain

import (
	"context"
	"time"
)

type PassengerActivitySummary struct {
	ThisWeekFareCentavos   int64 `json:"this_week_fare_centavos"`
	ThisWeekCompletedRides int   `json:"this_week_completed_rides"`
}

// PassengerActivityReader exposes the read-only passenger activity projection.
type PassengerActivityReader interface {
	PassengerActivitySummary(ctx context.Context, passengerID int, weekStart, weekEnd time.Time) (PassengerActivitySummary, error)
}

// PassengerActivitySummaryRepository preserves the legacy port name for existing callers.
type PassengerActivitySummaryRepository = PassengerActivityReader
