package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http/dto"
)

func rideResponseFromDomain(ride domain.Ride) dto.RideResponse {
	return dto.RideResponse{
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

func rideResponsesFromDomain(rides []domain.Ride) []dto.RideResponse {
	if rides == nil {
		return nil
	}

	responses := make([]dto.RideResponse, 0, len(rides))
	for _, ride := range rides {
		responses = append(responses, rideResponseFromDomain(ride))
	}
	return responses
}
