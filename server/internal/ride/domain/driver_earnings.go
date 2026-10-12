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
	EarningsAmount int64
	CompletedTrips int
}

type EarningsBucket struct {
	StartDate      string
	EarningsAmount int64
	CompletedTrips int
}

type DriverEarningsSummary struct {
	Timezone   string
	Today      EarningsPeriod
	ThisWeek   EarningsPeriod
	ThisMonth  EarningsPeriod
	Weekdays   []EarningsBucket
	MonthWeeks []EarningsBucket
}

type DriverEarningsReader interface {
	DriverEarnings(ctx context.Context, driverID int, monthStart, monthEnd time.Time) ([]DriverEarning, error)
}
