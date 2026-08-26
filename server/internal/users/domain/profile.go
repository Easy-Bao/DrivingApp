package domain

type Profile struct {
	ID                int     `json:"id"`
	UserID            int     `json:"user_id"`
	Role              string  `json:"role"`
	Name              string  `json:"name"`
	Phone             string  `json:"phone,omitempty"`
	Email             string  `json:"email,omitempty"`
	Address           string  `json:"address,omitempty"`
	Gender            string  `json:"gender,omitempty"`
	AvatarURL         string  `json:"avatar_url,omitempty"`
	PreferredRideType string  `json:"preferred_ride_type,omitempty"`
	VehicleType       string  `json:"vehicle_type,omitempty"`
	PlateNumber       string  `json:"plate_number,omitempty"`
	Rating            float64 `json:"rating,omitempty"`
	IsOnline          bool    `json:"is_online,omitempty"`
}
