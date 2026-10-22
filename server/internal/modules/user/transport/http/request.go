package http

type UpdateProfileRequest struct {
	Name    *string `json:"name"`
	Phone   *string `json:"phone"`
	Email   *string `json:"email"`
	Address *string `json:"address"`
	Gender  *string `json:"gender"`

	VehicleType *string `json:"vehicle_type"`
	PlateNumber *string `json:"plate_number"`
}
