package domain

type Counterparty struct {
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
