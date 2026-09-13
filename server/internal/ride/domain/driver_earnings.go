package domain

import (
	"context"
	"time"
)

type DriverEarning struct {
	CompletedAt  time.Time
	PayoutAmount int64
}

type EarningsPeriod struct {
	EarningsAmount int64 `json:"earnings_amount"`
	CompletedTrips int   `json:"completed_trips"`
}

type EarningsBucket struct {
	StartDate      string `json:"start_date"`
	EarningsAmount int64  `json:"earnings_amount"`
	CompletedTrips int    `json:"completed_trips"`
}

type DriverEarningsSummary struct {
	Timezone   string           `json:"timezone"`
	Today      EarningsPeriod   `json:"today"`
	ThisWeek   EarningsPeriod   `json:"this_week"`
	ThisMonth  EarningsPeriod   `json:"this_month"`
	Weekdays   []EarningsBucket `json:"weekdays"`
	MonthWeeks []EarningsBucket `json:"month_weeks"`
}

type DriverEarningsReader interface {
	DriverEarnings(ctx context.Context, driverID int, monthStart, monthEnd time.Time) ([]DriverEarning, error)
}

// DriverEarningsRepository is the legacy name for DriverEarningsReader.
//
// Deprecated: use DriverEarningsReader instead.
type DriverEarningsRepository = DriverEarningsReader
