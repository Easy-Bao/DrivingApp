package domain

import "errors"

var (
	ErrInvalidTrip             = errors.New("invalid trip details")
	ErrRouteUnavailable        = errors.New("route calculation is unavailable")
	ErrActiveBooking           = errors.New("passenger already has an active booking")
	ErrDriverAtCapacity        = errors.New("driver has reached the five-passenger capacity")
	ErrUnauthorizedRide        = errors.New("you are not a participant in this ride")
	ErrUnauthorizedSession     = errors.New("you are not a participant in this booking")
	ErrInvalidFareOffer        = errors.New("offer must not be lower than the calculated minimum fare")
	ErrInvalidSettlement       = errors.New("invalid settlement terms")
	ErrDriverUnavailable       = errors.New("driver is unavailable")
	ErrDuplicateBid            = errors.New("driver already submitted a bid for this ride")
	ErrInvalidStatusTransition = errors.New("invalid ride status transition")
	ErrReviewNotAllowed        = errors.New("reviews are allowed only after a completed ride")
	ErrReviewAlreadySubmitted  = errors.New("a review was already submitted for this ride")
)
