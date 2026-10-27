package domain

import "errors"

const MaxActiveRidesPerDriver = 5

var (
	ErrInvalidTrip               = errors.New("invalid trip details")
	ErrInvalidDriverStanding     = errors.New("invalid driver standing")
	ErrRouteUnavailable          = errors.New("route calculation is unavailable")
	ErrActiveBooking             = errors.New("passenger already has an active booking")
	ErrDriverCapacityReached     = errors.New("driver has reached the five active booking limit")
	ErrUnauthorizedRide          = errors.New("you are not a participant in this ride")
	ErrCounterpartyUnavailable   = errors.New("ride counterparty is unavailable")
	ErrInvalidSettlement         = errors.New("invalid settlement terms")
	ErrDriverUnavailable         = errors.New("driver is unavailable")
	ErrInvalidStatusTransition   = errors.New("invalid ride status transition")
	ErrInvalidCancellation       = errors.New("invalid ride cancellation")
	ErrCancellationCommand       = errors.New("ride cancellation requires a cancellation command")
	ErrArrivalCommand            = errors.New("ride arrival requires the arrival command")
	ErrTripStartCommand          = errors.New("trip start requires the start command")
	ErrTripCompletionCommand     = errors.New("trip completion requires the completion command")
	ErrArrivalLocation           = errors.New("driver is not close enough to the pickup")
	ErrDriverLocationUnavailable = errors.New("authoritative driver location is unavailable")
	ErrDriverLocationStale       = errors.New("authoritative driver location is stale")
	ErrPassengerNoShowNotReady   = errors.New("the passenger wait period has not elapsed")
	ErrNoShowCommand             = errors.New("passenger no-show requires the no-show command")
	ErrEmergencyStopNotAllowed   = errors.New("emergency stop is not available for this ride")
	ErrInvalidEmergencyStop      = errors.New("invalid emergency stop")
	ErrSafetyReportNotAllowed    = errors.New("you cannot report this ride")
	ErrSafetyReportInvalid       = errors.New("the safety report is invalid")
	ErrSafetyReportAlreadySent   = errors.New("this report was already submitted")
	ErrRideNotFound              = errors.New("ride not found")
)
