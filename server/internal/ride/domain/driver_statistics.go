package domain

import (
	"context"
	"time"
)

type DriverStats struct {
	DriverID            int            `json:"driver_id"`
	TotalTrips          int            `json:"total_trips"`
	CompletedTrips      int            `json:"completed_trips"`
	ActiveTrips         int            `json:"active_trips"`
	TotalEarnings       int64          `json:"total_earnings_amount"`
	TodayCompletedTrips int            `json:"today_completed_trips"`
	TodayEarnings       int64          `json:"today_earnings_amount"`
	AverageRating       float64        `json:"average_rating"`
	RatingDistribution  [5]int         `json:"rating_distribution"`
	Standing            DriverStanding `json:"standing"`
}

// DriverStanding exposes independent, evidence-based reliability metrics.
// It is deliberately not a single punitive score: responsibility categories
// let future policy distinguish driver fault from passenger, system, safety,
// and unresolved outcomes.
type DriverStanding struct {
	SettledTrips                       int     `json:"settled_trips"`
	DriverFaultCancellations           int     `json:"driver_fault_cancellations"`
	PassengerFaultCancellations        int     `json:"passenger_fault_cancellations"`
	SystemFaultCancellations           int     `json:"system_fault_cancellations"`
	NoFaultCancellations               int     `json:"no_fault_cancellations"`
	SafetyRelatedCancellations         int     `json:"safety_related_cancellations"`
	PendingReviewCancellations         int     `json:"pending_review_cancellations"`
	AdminOverrideCancellations         int     `json:"admin_override_cancellations"`
	CompletionRatePercent              float64 `json:"completion_rate_percent"`
	DriverFaultCancellationRatePercent float64 `json:"driver_fault_cancellation_rate_percent"`
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
