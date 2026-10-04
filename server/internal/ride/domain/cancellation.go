package domain

import (
	"strings"
	"unicode/utf8"
)

// CancellationActor identifies which participant initiated an ordinary
// cancellation. The server derives this from the ride aggregate instead of
// trusting a client-provided actor value.
type CancellationActor string

const (
	CancellationActorPassenger CancellationActor = "passenger"
	CancellationActorDriver    CancellationActor = "driver"
)

// CancellationReason is a stable code shared by the client, server, and
// future operations tooling. Labels belong in the clients; policy belongs in
// this domain boundary.
type CancellationReason string

const (
	CancellationReasonPassengerChangedMind     CancellationReason = "passenger_changed_mind"
	CancellationReasonFoundAnotherRide         CancellationReason = "found_another_ride"
	CancellationReasonWrongPickup              CancellationReason = "wrong_pickup_location"
	CancellationReasonDriverTakingTooLong      CancellationReason = "driver_taking_too_long"
	CancellationReasonDriverAskedToCancel      CancellationReason = "driver_asked_to_cancel"
	CancellationReasonDriverNoShow             CancellationReason = "driver_no_show"
	CancellationReasonPassengerRequestedCancel CancellationReason = "passenger_requested_cancellation"
	CancellationReasonPassengerUnreachable     CancellationReason = "passenger_unreachable"
	CancellationReasonPassengerNoShow          CancellationReason = "passenger_no_show"
	CancellationReasonPickupInaccessible       CancellationReason = "pickup_inaccessible"
	CancellationReasonVehicleProblem           CancellationReason = "vehicle_problem"
	CancellationReasonMedicalEmergency         CancellationReason = "medical_emergency"
	CancellationReasonRoadBlocked              CancellationReason = "road_blocked"
	CancellationReasonUnsafePickup             CancellationReason = "unsafe_pickup_location"
	CancellationReasonPassengerBehaviorUnsafe  CancellationReason = "passenger_behavior_unsafe"
	CancellationReasonAccident                 CancellationReason = "accident"
	CancellationReasonUnableToContinue         CancellationReason = "unable_to_continue"
	CancellationReasonOther                    CancellationReason = "other"
)

// CancellationResponsibility is a server-derived attribution used by later
// standing and dispute rules. It is intentionally separate from the reason:
// a safety incident may need review even when neither participant is at
// fault.
type CancellationResponsibility string

const (
	CancellationResponsibilityPassengerFault CancellationResponsibility = "passenger_fault"
	CancellationResponsibilityDriverFault    CancellationResponsibility = "driver_fault"
	CancellationResponsibilitySystemFault    CancellationResponsibility = "system_fault"
	CancellationResponsibilityNoFault        CancellationResponsibility = "no_fault"
	CancellationResponsibilitySafetyRelated  CancellationResponsibility = "safety_related"
	CancellationResponsibilityPendingReview  CancellationResponsibility = "pending_review"
	CancellationResponsibilityAdminOverride  CancellationResponsibility = "admin_override"
)

type CancellationRequest struct {
	RideID  int
	ActorID int
	Reason  CancellationReason
	Details string
}

// RideTransition is the evidence written in the same transaction as a ride
// status change. Empty reason and responsibility are valid for ordinary
// non-cancellation transitions.
type RideTransition struct {
	EventType      string
	Reason         CancellationReason
	Responsibility CancellationResponsibility
	Details        string
	RequestID      string
}

const (
	RideEventStatusChanged = "ride.status_changed"
	RideEventCancelled     = "ride.cancelled"
)

func NormalizeCancellationReason(value string) CancellationReason {
	return CancellationReason(strings.ToLower(strings.TrimSpace(value)))
}

func ValidateCancellation(
	actor CancellationActor,
	status string,
	reason CancellationReason,
	details string,
) (CancellationResponsibility, string, error) {
	normalizedStatus, ok := NormalizeRideStatus(status)
	if !ok || !CanTransition(string(normalizedStatus), string(RideCancelled)) {
		return "", "", ErrInvalidStatusTransition
	}

	normalizedReason := NormalizeCancellationReason(string(reason))
	normalizedDetails := strings.TrimSpace(details)
	if utf8.RuneCountInString(normalizedDetails) > 500 {
		return "", "", ErrInvalidCancellation
	}
	if normalizedReason == CancellationReasonOther && normalizedDetails == "" {
		return "", "", ErrInvalidCancellation
	}

	var responsibility CancellationResponsibility
	switch actor {
	case CancellationActorPassenger:
		if !isPassengerCancellationReason(normalizedReason) {
			return "", "", ErrInvalidCancellation
		}
		responsibility = passengerCancellationResponsibility(normalizedReason)
	case CancellationActorDriver:
		if !isDriverCancellationReason(normalizedReason) {
			return "", "", ErrInvalidCancellation
		}
		responsibility = driverCancellationResponsibility(normalizedReason)
	default:
		return "", "", ErrInvalidCancellation
	}
	return responsibility, normalizedDetails, nil
}

func isPassengerCancellationReason(reason CancellationReason) bool {
	switch reason {
	case CancellationReasonPassengerChangedMind,
		CancellationReasonFoundAnotherRide,
		CancellationReasonWrongPickup,
		CancellationReasonDriverTakingTooLong,
		CancellationReasonDriverAskedToCancel,
		CancellationReasonDriverNoShow,
		CancellationReasonOther:
		return true
	default:
		return false
	}
}

func isDriverCancellationReason(reason CancellationReason) bool {
	switch reason {
	case CancellationReasonPassengerRequestedCancel,
		CancellationReasonPassengerUnreachable,
		CancellationReasonPassengerNoShow,
		CancellationReasonPickupInaccessible,
		CancellationReasonVehicleProblem,
		CancellationReasonMedicalEmergency,
		CancellationReasonRoadBlocked,
		CancellationReasonUnsafePickup,
		CancellationReasonPassengerBehaviorUnsafe,
		CancellationReasonAccident,
		CancellationReasonUnableToContinue,
		CancellationReasonOther:
		return true
	default:
		return false
	}
}

func passengerCancellationResponsibility(reason CancellationReason) CancellationResponsibility {
	switch reason {
	case CancellationReasonDriverTakingTooLong,
		CancellationReasonDriverAskedToCancel,
		CancellationReasonDriverNoShow:
		return CancellationResponsibilityDriverFault
	case CancellationReasonOther:
		return CancellationResponsibilityPendingReview
	default:
		return CancellationResponsibilityPassengerFault
	}
}

func driverCancellationResponsibility(reason CancellationReason) CancellationResponsibility {
	switch reason {
	case CancellationReasonPassengerRequestedCancel,
		CancellationReasonPassengerUnreachable,
		CancellationReasonPassengerNoShow,
		CancellationReasonPassengerBehaviorUnsafe:
		return CancellationResponsibilityPassengerFault
	case CancellationReasonVehicleProblem:
		return CancellationResponsibilityDriverFault
	case CancellationReasonMedicalEmergency,
		CancellationReasonUnsafePickup,
		CancellationReasonAccident:
		return CancellationResponsibilitySafetyRelated
	case CancellationReasonRoadBlocked,
		CancellationReasonPickupInaccessible,
		CancellationReasonUnableToContinue:
		return CancellationResponsibilityNoFault
	case CancellationReasonOther:
		return CancellationResponsibilityPendingReview
	default:
		return CancellationResponsibilityPendingReview
	}
}
