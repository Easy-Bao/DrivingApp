package domain

type PendingRegistration struct {
	Email             string `json:"email"`
	Phone             string `json:"phone"`
	Name              string `json:"name"`
	PasswordHash      string `json:"password_hash"`
	Role              Role   `json:"role"`
	VehicleType       string `json:"vehicle_type,omitempty"`
	PlateNumber       string `json:"plate_number,omitempty"`
	PreferredRideType string `json:"preferred_ride_type,omitempty"`
}
