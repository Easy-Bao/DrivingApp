package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"

type OnlineDriverResponse struct {
	ID                    int     `json:"id"`
	UserID                int     `json:"user_id"`
	Name                  string  `json:"name"`
	VehicleType           string  `json:"vehicle_type"`
	PlateNumber           string  `json:"plate_number"`
	Rating                float64 `json:"rating"`
	OnboardPassengerCount int     `json:"onboard_passenger_count"`
}

type PublicDriverSummaryResponse struct {
	ID          int     `json:"id"`
	Name        string  `json:"name"`
	VehicleType string  `json:"vehicle_type"`
	Rating      float64 `json:"rating"`
}

func NewOnlineDriverResponses(drivers []domain.OnlineDriver) []OnlineDriverResponse {
	if drivers == nil {
		return nil
	}

	responses := make([]OnlineDriverResponse, 0, len(drivers))
	for _, driver := range drivers {
		responses = append(responses, OnlineDriverResponse{
			ID:                    driver.ID,
			UserID:                driver.UserID,
			Name:                  driver.Name,
			VehicleType:           driver.VehicleType,
			PlateNumber:           driver.PlateNumber,
			Rating:                driver.Rating,
			OnboardPassengerCount: driver.OnboardPassengerCount,
		})
	}
	return responses
}

func NewPublicDriverSummaryResponses(
	drivers []domain.PublicDriverSummary,
) []PublicDriverSummaryResponse {
	if drivers == nil {
		return nil
	}

	responses := make([]PublicDriverSummaryResponse, 0, len(drivers))
	for _, driver := range drivers {
		responses = append(responses, PublicDriverSummaryResponse{
			ID:          driver.ID,
			Name:        driver.Name,
			VehicleType: driver.VehicleType,
			Rating:      driver.Rating,
		})
	}
	return responses
}
