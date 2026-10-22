package domain

type PendingRegistration struct {
	Email        string
	Phone        string
	Name         string
	PasswordHash string
	Role         Role
	VehicleType  string
	PlateNumber  string
}
