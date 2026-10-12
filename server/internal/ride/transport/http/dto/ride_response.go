package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"

type RideResponse struct {
	ID                         int     `json:"id"`
	PassengerID                int     `json:"passenger_id"`
	DriverID                   *int    `json:"driver_id,omitempty"`
	Status                     string  `json:"status"`
	FareAmount                 int64   `json:"fare_amount"`
	RideType                   string  `json:"ride_type,omitempty"`
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
		ID:                         ride.ID,
		PassengerID:                ride.PassengerID,
		DriverID:                   ride.DriverID,
		Status:                     ride.Status,
		FareAmount:                 ride.FareAmount,
		RideType:                   ride.RideType,
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
		CancelledBy:                ride.CancelledBy,
		CancellationReason:         ride.CancellationReason,
		CancellationResponsibility: ride.CancellationResponsibility,
		CancellationDetails:        ride.CancellationDetails,
		CommissionBPS:              ride.CommissionBPS,
		CommissionAmount:           ride.CommissionAmount,
		DriverPayoutAmount:         ride.DriverPayoutAmount,
	}
}
