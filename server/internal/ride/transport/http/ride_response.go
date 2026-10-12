package http

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http/dto"
)

func rideResponseFromDomain(ride domain.Ride) dto.RideResponse {
	return dto.NewRideResponse(ride)
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
