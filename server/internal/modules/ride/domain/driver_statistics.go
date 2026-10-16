package domain

import (
	"context"
	"time"
)

type DriverStats struct {
	DriverID            int
	TotalTrips          int
	CompletedTrips      int
	ActiveTrips         int
	TotalEarnings       int64
	TodayCompletedTrips int
	TodayEarnings       int64
	AverageRating       float64
	RatingDistribution  [5]int
	Standing            DriverStanding
}

// DriverStanding exposes independent, evidence-based reliability metrics.
// It is deliberately not a single punitive score: responsibility categories
// let future policy distinguish driver fault from passenger, system, safety,
// and unresolved outcomes.
type DriverStanding struct {
	SettledTrips                       int
	DriverFaultCancellations           int
	PassengerFaultCancellations        int
	SystemFaultCancellations           int
	NoFaultCancellations               int
	SafetyRelatedCancellations         int
	PendingReviewCancellations         int
	AdminOverrideCancellations         int
	CompletionRatePercent              float64
	DriverFaultCancellationRatePercent float64
}

func BuildDriverStanding(
	settledTrips,
	completedTrips,
	driverFaultCancellations,
	passengerFaultCancellations,
	systemFaultCancellations,
	noFaultCancellations,
	safetyRelatedCancellations,
	pendingReviewCancellations,
	adminOverrideCancellations int,
) (DriverStanding, error) {
	counts := []int{
		settledTrips,
		completedTrips,
		driverFaultCancellations,
		passengerFaultCancellations,
		systemFaultCancellations,
		noFaultCancellations,
		safetyRelatedCancellations,
		pendingReviewCancellations,
		adminOverrideCancellations,
	}
	for _, count := range counts {
		if count < 0 {
			return DriverStanding{}, ErrInvalidDriverStanding
		}
	}
	if completedTrips > settledTrips {
		return DriverStanding{}, ErrInvalidDriverStanding
	}

	standing := DriverStanding{
		SettledTrips:                settledTrips,
		DriverFaultCancellations:    driverFaultCancellations,
		PassengerFaultCancellations: passengerFaultCancellations,
		SystemFaultCancellations:    systemFaultCancellations,
		NoFaultCancellations:        noFaultCancellations,
		SafetyRelatedCancellations:  safetyRelatedCancellations,
		PendingReviewCancellations:  pendingReviewCancellations,
		AdminOverrideCancellations:  adminOverrideCancellations,
	}
	if settledTrips == 0 {
		return standing, nil
	}
	standing.CompletionRatePercent = float64(completedTrips) / float64(settledTrips) * 100
	standing.DriverFaultCancellationRatePercent = float64(driverFaultCancellations) / float64(settledTrips) * 100
	return standing, nil
}

type DriverStatisticsReader interface {
	DriverStats(ctx context.Context, driverID int, dayStart, dayEnd time.Time) (DriverStats, error)
}
