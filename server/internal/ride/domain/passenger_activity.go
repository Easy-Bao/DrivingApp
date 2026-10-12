package domain

import (
	"context"
	"time"
)

type PassengerActivitySummary struct {
	ThisWeekFareAmount     int64
	ThisWeekCompletedRides int
}

type PassengerActivityReader interface {
	PassengerActivitySummary(
		ctx context.Context,
		passengerID int,
		weekStart time.Time,
		weekEnd time.Time,
	) (PassengerActivitySummary, error)
}
