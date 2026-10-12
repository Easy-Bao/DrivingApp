package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"

type EarningsPeriodResponse struct {
	EarningsAmount int64 `json:"earnings_amount"`
	CompletedTrips int   `json:"completed_trips"`
}

type EarningsBucketResponse struct {
	StartDate      string `json:"start_date"`
	EarningsAmount int64  `json:"earnings_amount"`
	CompletedTrips int    `json:"completed_trips"`
}

type DriverEarningsResponse struct {
	Timezone   string                   `json:"timezone"`
	Today      EarningsPeriodResponse   `json:"today"`
	ThisWeek   EarningsPeriodResponse   `json:"this_week"`
	ThisMonth  EarningsPeriodResponse   `json:"this_month"`
	Weekdays   []EarningsBucketResponse `json:"weekdays"`
	MonthWeeks []EarningsBucketResponse `json:"month_weeks"`
}

type DriverStandingResponse struct {
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

type DriverStatsResponse struct {
	DriverID            int                    `json:"driver_id"`
	TotalTrips          int                    `json:"total_trips"`
	CompletedTrips      int                    `json:"completed_trips"`
	ActiveTrips         int                    `json:"active_trips"`
	TotalEarnings       int64                  `json:"total_earnings_amount"`
	TodayCompletedTrips int                    `json:"today_completed_trips"`
	TodayEarnings       int64                  `json:"today_earnings_amount"`
	AverageRating       float64                `json:"average_rating"`
	RatingDistribution  [5]int                 `json:"rating_distribution"`
	Standing            DriverStandingResponse `json:"standing"`
}

type PassengerActivitySummaryResponse struct {
	ThisWeekFareAmount     int64 `json:"this_week_fare_amount"`
	ThisWeekCompletedRides int   `json:"this_week_completed_rides"`
}

func NewDriverEarningsResponse(summary domain.DriverEarningsSummary) DriverEarningsResponse {
	return DriverEarningsResponse{
		Timezone:   summary.Timezone,
		Today:      newEarningsPeriodResponse(summary.Today),
		ThisWeek:   newEarningsPeriodResponse(summary.ThisWeek),
		ThisMonth:  newEarningsPeriodResponse(summary.ThisMonth),
		Weekdays:   newEarningsBucketResponses(summary.Weekdays),
		MonthWeeks: newEarningsBucketResponses(summary.MonthWeeks),
	}
}

func NewDriverStatsResponse(stats domain.DriverStats) DriverStatsResponse {
	return DriverStatsResponse{
		DriverID:            stats.DriverID,
		TotalTrips:          stats.TotalTrips,
		CompletedTrips:      stats.CompletedTrips,
		ActiveTrips:         stats.ActiveTrips,
		TotalEarnings:       stats.TotalEarnings,
		TodayCompletedTrips: stats.TodayCompletedTrips,
		TodayEarnings:       stats.TodayEarnings,
		AverageRating:       stats.AverageRating,
		RatingDistribution:  stats.RatingDistribution,
		Standing:            newDriverStandingResponse(stats.Standing),
	}
}

func NewPassengerActivitySummaryResponse(
	summary domain.PassengerActivitySummary,
) PassengerActivitySummaryResponse {
	return PassengerActivitySummaryResponse{
		ThisWeekFareAmount:     summary.ThisWeekFareAmount,
		ThisWeekCompletedRides: summary.ThisWeekCompletedRides,
	}
}

func newEarningsPeriodResponse(period domain.EarningsPeriod) EarningsPeriodResponse {
	return EarningsPeriodResponse{
		EarningsAmount: period.EarningsAmount,
		CompletedTrips: period.CompletedTrips,
	}
}

func newEarningsBucketResponses(buckets []domain.EarningsBucket) []EarningsBucketResponse {
	if buckets == nil {
		return nil
	}

	responses := make([]EarningsBucketResponse, 0, len(buckets))
	for _, bucket := range buckets {
		responses = append(responses, EarningsBucketResponse{
			StartDate:      bucket.StartDate,
			EarningsAmount: bucket.EarningsAmount,
			CompletedTrips: bucket.CompletedTrips,
		})
	}
	return responses
}

func newDriverStandingResponse(standing domain.DriverStanding) DriverStandingResponse {
	return DriverStandingResponse{
		SettledTrips:                       standing.SettledTrips,
		DriverFaultCancellations:           standing.DriverFaultCancellations,
		PassengerFaultCancellations:        standing.PassengerFaultCancellations,
		SystemFaultCancellations:           standing.SystemFaultCancellations,
		NoFaultCancellations:               standing.NoFaultCancellations,
		SafetyRelatedCancellations:         standing.SafetyRelatedCancellations,
		PendingReviewCancellations:         standing.PendingReviewCancellations,
		AdminOverrideCancellations:         standing.AdminOverrideCancellations,
		CompletionRatePercent:              standing.CompletionRatePercent,
		DriverFaultCancellationRatePercent: standing.DriverFaultCancellationRatePercent,
	}
}
