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
	ID                int        `json:"id"`
	PassengerID       int        `json:"passenger_id"`
	RideType          string     `json:"ride_type"`
	PickupLatitude    float64    `json:"pickup_latitude"`
	PickupLongitude   float64    `json:"pickup_longitude"`
	PickupName        string     `json:"pickup_name"`
	DropoffLatitude   float64    `json:"dropoff_latitude"`
	DropoffLongitude  float64    `json:"dropoff_longitude"`
	DropoffName       string     `json:"dropoff_name"`
	PassengerNote     string     `json:"passenger_note,omitempty"`
	DistanceKm        float64    `json:"distance_km"`
	DurationMinutes   float64    `json:"duration_minutes"`
	OfferedFareAmount int64      `json:"offered_fare"`
	CustomFareAmount  *int64     `json:"custom_fare,omitempty"`
	Status            string     `json:"status"`
	TargetDriverID    *int       `json:"target_driver_id,omitempty"`
	AcceptedDriverID  *int       `json:"accepted_driver_id,omitempty"`
	ExpiresAt         time.Time  `json:"expires_at"`
	CreatedAt         time.Time  `json:"created_at"`
	Offers            []BidOffer `json:"offers,omitempty"`
}

type BidOffer struct {
	ID                 int64     `json:"id"`
	SessionID          int       `json:"session_id"`
	DriverID           int       `json:"driver_id"`
	DriverName         string    `json:"driver_name,omitempty"`
	PlateNumber        string    `json:"plate_number,omitempty"`
	VehicleType        string    `json:"vehicle_type,omitempty"`
	ProposedFareAmount int64     `json:"proposed_fare"`
	Status             string    `json:"status"`
	CreatedAt          time.Time `json:"created_at"`
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
