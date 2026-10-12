package domain

import "time"

type Ride struct {
	ID                         int
	PassengerID                int
	DriverID                   *int
	Status                     string
	FareAmount                 int64
	RideType                   string
	PickupLatitude             float64
	PickupLongitude            float64
	PickupName                 string
	DropoffLatitude            float64
	DropoffLongitude           float64
	DropoffName                string
	DistanceKm                 float64
	DurationMinutes            float64
	DriverName                 string
	VehicleType                string
	PlateNumber                string
	DriverRating               float64
	PassengerName              string
	PassengerPhone             string
	PassengerRating            float64
	PassengerFeedback          string
	CreatedAt                  *string
	CompletedAt                *string
	ArrivedAt                  *string
	WaitingUntil               *string
	PaymentStatus              string
	CashReceivedAmount         int64
	CashChangeAmount           int64
	CashOutcome                string
	CancelledBy                *int
	CancellationReason         string
	CancellationResponsibility string
	CancellationDetails        string
	CommissionBPS              *int64
	CommissionAmount           int64
	DriverPayoutAmount         int64
}
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

// BidOfferWithdrawal pairs an offer rejected because its driver became busy
// with the session whose passenger must receive the update.
type BidOfferWithdrawal struct {
	Session BidSession
	Offer   BidOffer
}

// OfferAcceptance is the atomic persistence result of accepting one bid.
type OfferAcceptance struct {
	Session         BidSession
	Offer           BidOffer
	Ride            Ride
	WithdrawnOffers []BidOfferWithdrawal
}
