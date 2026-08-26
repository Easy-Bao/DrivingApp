package domain

import "strings"

type RideStatus string

const (
	RideRequested RideStatus = "requested"
	RideAssigned  RideStatus = "assigned"
	RideAccepted  RideStatus = "accepted"
	RideArrived   RideStatus = "arrived"
	RideInTransit RideStatus = "in_transit"
	RideCompleted RideStatus = "completed"
	RideCancelled RideStatus = "cancelled"
)

// NormalizeRideStatus keeps legacy spelling at the boundary while allowing
// storage, events, and clients to use one canonical lifecycle value.
func NormalizeRideStatus(value string) (RideStatus, bool) {
	status := RideStatus(strings.ToLower(strings.TrimSpace(value)))
	if status == "canceled" {
		status = RideCancelled
	}
	switch status {
	case RideRequested, RideAssigned, RideAccepted, RideArrived, RideInTransit, RideCompleted, RideCancelled:
		return status, true
	default:
		return "", false
	}
}

func CanTransition(current, next string) bool {
	from, fromOK := NormalizeRideStatus(current)
	to, toOK := NormalizeRideStatus(next)
	if !fromOK || !toOK {
		return false
	}
	switch from {
	case RideRequested:
		return to == RideAssigned || to == RideAccepted || to == RideCancelled
	case RideAssigned:
		return to == RideArrived || to == RideCancelled
	case RideAccepted:
		return to == RideArrived || to == RideCancelled
	case RideArrived:
		return to == RideInTransit || to == RideCancelled
	case RideInTransit:
		return to == RideCompleted || to == RideCancelled
	default:
		return false
	}
}

func IsActive(status string) bool {
	normalized, ok := NormalizeRideStatus(status)
	if !ok {
		return false
	}
	switch normalized {
	case RideRequested, RideAssigned, RideAccepted, RideArrived, RideInTransit:
		return true
	default:
		return false
	}
}

func IsTerminal(status string) bool {
	normalized, ok := NormalizeRideStatus(status)
	return ok && (normalized == RideCompleted || normalized == RideCancelled)
}
