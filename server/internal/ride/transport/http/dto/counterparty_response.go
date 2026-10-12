package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"

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
