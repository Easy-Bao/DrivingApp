package dto

type UpdateProfileRequest struct {
	Name              *string `json:"name"`
	Phone             *string `json:"phone"`
	Email             *string `json:"email"`
	Address           *string `json:"address"`
	PreferredRideType *string `json:"preferred_ride_type"`
	VehicleType       *string `json:"vehicle_type"`
	PlateNumber       *string `json:"plate_number"`
}
