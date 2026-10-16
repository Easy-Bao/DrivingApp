package domain

import (
	"errors"
	"testing"
)

func TestValidateEmergencyStopRequiresAnEligibleActiveRide(t *testing.T) {
	if _, _, err := ValidateEmergencyStop(
		string(RideCompleted),
		EmergencyStopReasonAccident,
		"",
	); !errors.Is(err, ErrEmergencyStopNotAllowed) {
		t.Fatalf("error = %v, want ErrEmergencyStopNotAllowed", err)
	}
}

func TestValidateEmergencyStopNormalizesAndBoundsEvidence(t *testing.T) {
	reason, details, err := ValidateEmergencyStop(
		string(RideInTransit),
		EmergencyStopReason(" THREAT_OR_VIOLENCE "),
		" Passenger threatened the driver ",
	)
	if err != nil {
		t.Fatalf("ValidateEmergencyStop() error = %v", err)
	}
	if reason != EmergencyStopReasonThreatOrViolence {
		t.Fatalf("reason = %q, want %q", reason, EmergencyStopReasonThreatOrViolence)
	}
	if details != "Passenger threatened the driver" {
		t.Fatalf("details = %q", details)
	}
}

func TestValidateEmergencyStopRequiresDetailsForOther(t *testing.T) {
	if _, _, err := ValidateEmergencyStop(
		string(RideArrived),
		EmergencyStopReasonOther,
		" ",
	); !errors.Is(err, ErrInvalidEmergencyStop) {
		t.Fatalf("error = %v, want ErrInvalidEmergencyStop", err)
	}
}
