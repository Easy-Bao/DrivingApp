package domain

type Role string

const (
	Passenger Role = "passenger"
	Driver    Role = "driver"
)

type User struct {
	ID                int
	Email             string
	Phone             string
	Name              string
	Role              Role
	PasswordHash      string
	IsVerified        bool
	VehicleType       string
	PlateNumber       string
	PreferredRideType string
	AccountStatus     string
}
