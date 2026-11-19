package domain

import "time"

const CompletedContactWindow = 24 * time.Hour

type Assignment struct {
	RideID      string
	DriverID    string
	PassengerID string
	Status      string
	ContactOpen bool
	CompletedAt *time.Time
}

func (value Assignment) AllowsCommunication() bool {
	if value.Active() {
		return true
	}
	if value.Status != "completed" {
		return false
	}
	if value.CompletedAt != nil {
		age := time.Since(*value.CompletedAt)
		return age >= 0 && age <= CompletedContactWindow
	}
	return value.ContactOpen
}

func (value Assignment) Active() bool {
	switch value.Status {
	case "assigned", "accepted", "arrived", "in_transit":
		return true
	default:
		return false
	}
}
