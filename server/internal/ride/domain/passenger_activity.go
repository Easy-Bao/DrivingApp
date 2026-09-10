package domain

import (
	"context"
	"time"
)

type PassengerActivitySummary struct {
	ThisWeekFareCentavos   int64 `json:"this_week_fare_centavos"`
	ThisWeekCompletedRides int   `json:"this_week_completed_rides"`
}

// PassengerActivityReader supplies dashboard activity without exposing ride
// command persistence.
type PassengerActivityReader interface {
	PassengerActivitySummary(ctx context.Context, passengerID int, weekStart, weekEnd time.Time) (PassengerActivitySummary, error)
}

// PassengerActivitySummaryRepository is the legacy name for
// PassengerActivityReader.
//
// Deprecated: use PassengerActivityReader instead.
type PassengerActivitySummaryRepository = PassengerActivityReader
