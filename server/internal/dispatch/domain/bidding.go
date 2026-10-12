package domain

import (
	"errors"
	"time"
)

var (
	ErrUnauthorizedSession = errors.New("you are not a participant in this booking")
	ErrInvalidFareOffer    = errors.New("offer must not be lower than the calculated minimum fare")
	ErrDriverUnavailable   = errors.New("driver is unavailable")
	ErrDuplicateBid        = errors.New("driver already submitted a bid for this ride")
)

type BidSession struct {
	ID                int
	PassengerID       int
	RideType          string
	PickupLatitude    float64
	PickupLongitude   float64
	PickupName        string
	DropoffLatitude   float64
	DropoffLongitude  float64
	DropoffName       string
	PassengerNote     string
	DistanceKm        float64
	DurationMinutes   float64
	OfferedFareAmount int64
	CustomFareAmount  *int64
	Status            string
	TargetDriverID    *int
	AcceptedDriverID  *int
	ExpiresAt         time.Time
	CreatedAt         time.Time
	Offers            []BidOffer
}

type BidOffer struct {
	ID                 int64
	SessionID          int
	DriverID           int
	DriverName         string
	PlateNumber        string
	VehicleType        string
	ProposedFareAmount int64
	Status             string
	CreatedAt          time.Time
}

type BidOfferWithdrawal struct {
	Session BidSession
	Offer   BidOffer
}
