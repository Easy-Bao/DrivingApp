package http

import "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"

type RideResponse struct {
	ID               int    `json:"id"`
	BookingReference string `json:"booking_reference,omitempty"`
	PassengerID      int    `json:"passenger_id"`
	DriverID         *int   `json:"driver_id,omitempty"`
	Status           string `json:"status"`
	FareAmount       int64  `json:"fare_amount"`

	PickupLatitude             float64 `json:"pickup_latitude,omitempty"`
	PickupLongitude            float64 `json:"pickup_longitude,omitempty"`
	PickupName                 string  `json:"pickup_name,omitempty"`
	DropoffLatitude            float64 `json:"dropoff_latitude,omitempty"`
	DropoffLongitude           float64 `json:"dropoff_longitude,omitempty"`
	DropoffName                string  `json:"dropoff_name,omitempty"`
	DistanceKm                 float64 `json:"distance_km,omitempty"`
	DurationMinutes            float64 `json:"duration_minutes,omitempty"`
	DriverName                 string  `json:"driver_name,omitempty"`
	VehicleType                string  `json:"vehicle_type,omitempty"`
	PlateNumber                string  `json:"plate_number,omitempty"`
	DriverRating               float64 `json:"driver_rating,omitempty"`
	PassengerName              string  `json:"passenger_name,omitempty"`
	PassengerPhone             string  `json:"passenger_phone,omitempty"`
	PassengerRating            float64 `json:"passenger_rating,omitempty"`
	PassengerFeedback          string  `json:"passenger_feedback,omitempty"`
	CreatedAt                  *string `json:"created_at,omitempty"`
	CompletedAt                *string `json:"completed_at,omitempty"`
	ArrivedAt                  *string `json:"arrived_at,omitempty"`
	WaitingUntil               *string `json:"waiting_until,omitempty"`
	PaymentStatus              string  `json:"payment_status"`
	CashReceivedAmount         int64   `json:"cash_received_amount"`
	CashChangeAmount           int64   `json:"cash_change_amount"`
	CashOutcome                string  `json:"cash_outcome"`
	CashSettled                bool    `json:"cash_settled"`
	CancelledBy                *int    `json:"cancelled_by,omitempty"`
	CancellationReason         string  `json:"cancellation_reason,omitempty"`
	CancellationResponsibility string  `json:"cancellation_responsibility,omitempty"`
	CancellationDetails        string  `json:"cancellation_details,omitempty"`
	CommissionBPS              *int64  `json:"commission_bps,omitempty"`
	CommissionAmount           int64   `json:"commission_amount"`
	DriverPayoutAmount         int64   `json:"driver_payout_amount"`
}

func NewRideResponse(ride domain.Ride) RideResponse {
	return RideResponse{
		ID:               ride.ID,
		BookingReference: ride.BookingReference,
		PassengerID:      ride.PassengerID,
		DriverID:         ride.DriverID,
		Status:           ride.Status,
		FareAmount:       ride.FareAmount,

		PickupLatitude:             ride.PickupLatitude,
		PickupLongitude:            ride.PickupLongitude,
		PickupName:                 ride.PickupName,
		DropoffLatitude:            ride.DropoffLatitude,
		DropoffLongitude:           ride.DropoffLongitude,
		DropoffName:                ride.DropoffName,
		DistanceKm:                 ride.DistanceKm,
		DurationMinutes:            ride.DurationMinutes,
		DriverName:                 ride.DriverName,
		VehicleType:                ride.VehicleType,
		PlateNumber:                ride.PlateNumber,
		DriverRating:               ride.DriverRating,
		PassengerName:              ride.PassengerName,
		PassengerPhone:             ride.PassengerPhone,
		PassengerRating:            ride.PassengerRating,
		PassengerFeedback:          ride.PassengerFeedback,
		CreatedAt:                  ride.CreatedAt,
		CompletedAt:                ride.CompletedAt,
		ArrivedAt:                  ride.ArrivedAt,
		WaitingUntil:               ride.WaitingUntil,
		PaymentStatus:              ride.PaymentStatus,
		CashReceivedAmount:         ride.CashReceivedAmount,
		CashChangeAmount:           ride.CashChangeAmount,
		CashOutcome:                ride.CashOutcome,
		CashSettled:                ride.CashSettled,
		CancelledBy:                ride.CancelledBy,
		CancellationReason:         ride.CancellationReason,
		CancellationResponsibility: ride.CancellationResponsibility,
		CancellationDetails:        ride.CancellationDetails,
		CommissionBPS:              ride.CommissionBPS,
		CommissionAmount:           ride.CommissionAmount,
		DriverPayoutAmount:         ride.DriverPayoutAmount,
	}
}

func rideResponseFromDomain(ride domain.Ride) RideResponse {
	return NewRideResponse(ride)
}

func rideResponsesFromDomain(rides []domain.Ride) []RideResponse {
	if rides == nil {
		return nil
	}

	responses := make([]RideResponse, 0, len(rides))
	for _, ride := range rides {
		responses = append(responses, rideResponseFromDomain(ride))
	}
	return responses
}

type CounterpartyResponse struct {
	RideID              int     `json:"ride_id"`
	UserID              int     `json:"user_id"`
	Role                string  `json:"role"`
	Name                string  `json:"name"`
	Phone               string  `json:"phone,omitempty"`
	Rating              float64 `json:"rating,omitempty"`
	VehicleType         string  `json:"vehicle_type,omitempty"`
	PlateNumber         string  `json:"plate_number,omitempty"`
	RideStatus          string  `json:"ride_status"`
	ContactAllowed      bool    `json:"contact_allowed"`
	ContactAllowedUntil *string `json:"contact_allowed_until,omitempty"`
}

func NewCounterpartyResponse(counterparty domain.Counterparty) CounterpartyResponse {
	return CounterpartyResponse{
		RideID:              counterparty.RideID,
		UserID:              counterparty.UserID,
		Role:                counterparty.Role,
		Name:                counterparty.Name,
		Phone:               counterparty.Phone,
		Rating:              counterparty.Rating,
		VehicleType:         counterparty.VehicleType,
		PlateNumber:         counterparty.PlateNumber,
		RideStatus:          counterparty.RideStatus,
		ContactAllowed:      counterparty.ContactAllowed,
		ContactAllowedUntil: counterparty.ContactAllowedUntil,
	}
}

type SafetyReportResponse struct {
	ID             int                         `json:"id"`
	RideID         int                         `json:"ride_id"`
	ReporterID     int                         `json:"reporter_id"`
	ReportedUserID int                         `json:"reported_user_id"`
	ReporterRole   string                      `json:"reporter_role"`
	Category       domain.SafetyReportCategory `json:"category"`
	Severity       domain.SafetyReportSeverity `json:"severity"`
	Description    string                      `json:"description"`
	Status         domain.SafetyReportStatus   `json:"status"`
	CreatedAt      string                      `json:"created_at"`
}

func NewSafetyReportResponse(report domain.SafetyReport) SafetyReportResponse {
	return SafetyReportResponse{
		ID:             report.ID,
		RideID:         report.RideID,
		ReporterID:     report.ReporterID,
		ReportedUserID: report.ReportedUserID,
		ReporterRole:   report.ReporterRole,
		Category:       report.Category,
		Severity:       report.Severity,
		Description:    report.Description,
		Status:         report.Status,
		CreatedAt:      report.CreatedAt,
	}
}

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
