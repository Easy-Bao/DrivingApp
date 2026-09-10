package domain

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
