package domain

import (
	"context"
	"time"
)

type PassengerActivitySummary struct {
	ThisWeekFareAmount     int64 `json:"this_week_fare_amount"`
	ThisWeekCompletedRides int   `json:"this_week_completed_rides"`
}

type PassengerActivityReader interface {
	PassengerActivitySummary(
		ctx context.Context,
		passengerID int,
		weekStart time.Time,
		weekEnd time.Time,
	) (PassengerActivitySummary, error)
}

// PassengerActivitySummaryRepository is the legacy name for
// PassengerActivityReader.
//
// Deprecated: use PassengerActivityReader instead.
type PassengerActivitySummaryRepository = PassengerActivityReader
