package domain

type Role string

const (
	Passenger Role = "passenger"
	Driver    Role = "driver"
)

type User struct {
	ID                int    `json:"id"`
	Email             string `json:"email"`
	Phone             string `json:"phone"`
	Name              string `json:"name"`
	Role              Role   `json:"role"`
	PasswordHash      string `json:"-"`
	IsVerified        bool   `json:"isVerified"`
	VehicleType       string `json:"vehicleType,omitempty"`
	PlateNumber       string `json:"plateNumber,omitempty"`
	PreferredRideType string `json:"preferred_ride_type,omitempty"`
}
