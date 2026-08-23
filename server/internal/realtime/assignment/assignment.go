package assignment

import "context"

type Assignment struct {
	RideID      string
	DriverID    string
	PassengerID string
	Status      string
	ContactOpen bool
}

func (value Assignment) AllowsCommunication() bool {
	return value.Active() || (value.Status == "completed" && value.ContactOpen)
}

func (value Assignment) Active() bool {
	switch value.Status {
	case "assigned", "accepted", "arrived", "in_transit":
		return true
	default:
		return false
	}
}

type Lookup interface {
	ForRide(ctx context.Context, rideID string) (Assignment, bool, error)
	ForDriver(ctx context.Context, driverID string) ([]Assignment, error)
}
