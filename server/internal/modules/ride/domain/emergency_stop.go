package domain

import (
	"strings"
	"unicode/utf8"
)

// EmergencyStopReason identifies why a participant had to end an active ride
// early. It is stored with the ride event so the stop is not mistaken for an
// ordinary cancellation.
type EmergencyStopReason string

const (
	EmergencyStopReasonAccident         EmergencyStopReason = "accident"
	EmergencyStopReasonMedicalEmergency EmergencyStopReason = "medical_emergency"
	EmergencyStopReasonThreatOrViolence EmergencyStopReason = "threat_or_violence"
	EmergencyStopReasonVehicleBreakdown EmergencyStopReason = "vehicle_breakdown"
	EmergencyStopReasonRoadHazard       EmergencyStopReason = "road_hazard"
	EmergencyStopReasonPoliceOrDisaster EmergencyStopReason = "police_or_disaster"
	EmergencyStopReasonOther            EmergencyStopReason = "other"
)

type EmergencyStopRequest struct {
	RideID  int
	ActorID int
	Reason  EmergencyStopReason
	Details string
}

func NormalizeEmergencyStopReason(value string) EmergencyStopReason {
	return EmergencyStopReason(strings.ToLower(strings.TrimSpace(value)))
}

func ValidateEmergencyStop(
	status string,
	reason EmergencyStopReason,
	details string,
) (EmergencyStopReason, string, error) {
	if !CanEmergencyStop(status) {
		return "", "", ErrEmergencyStopNotAllowed
	}

	normalizedReason := NormalizeEmergencyStopReason(string(reason))
	normalizedDetails := strings.TrimSpace(details)
	if utf8.RuneCountInString(normalizedDetails) > 500 {
		return "", "", ErrInvalidEmergencyStop
	}
	if normalizedReason == EmergencyStopReasonOther && normalizedDetails == "" {
		return "", "", ErrInvalidEmergencyStop
	}

	switch normalizedReason {
	case EmergencyStopReasonAccident,
		EmergencyStopReasonMedicalEmergency,
		EmergencyStopReasonThreatOrViolence,
		EmergencyStopReasonVehicleBreakdown,
		EmergencyStopReasonRoadHazard,
		EmergencyStopReasonPoliceOrDisaster,
		EmergencyStopReasonOther:
		return normalizedReason, normalizedDetails, nil
	default:
		return "", "", ErrInvalidEmergencyStop
	}
}
