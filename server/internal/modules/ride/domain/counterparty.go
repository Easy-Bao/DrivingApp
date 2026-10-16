package domain

type Counterparty struct {
	RideID              int
	UserID              int
	Role                string
	Name                string
	Phone               string
	Rating              float64
	VehicleType         string
	PlateNumber         string
	RideStatus          string
	ContactAllowed      bool
	ContactAllowedUntil *string
}
