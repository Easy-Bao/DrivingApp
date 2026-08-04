package domain

import "time"

type Ride struct {
	ID               int     `json:"id"`
	PassengerID      int     `json:"passenger_id"`
	DriverID         *int    `json:"driver_id,omitempty"`
	Status           string  `json:"status"`
	FareCentavos     int64   `json:"fare_centavos"`
	RideType         string  `json:"ride_type,omitempty"`
	PickupLatitude   float64 `json:"pickup_latitude,omitempty"`
	PickupLongitude  float64 `json:"pickup_longitude,omitempty"`
	PickupName       string  `json:"pickup_name,omitempty"`
	DropoffLatitude  float64 `json:"dropoff_latitude,omitempty"`
	DropoffLongitude float64 `json:"dropoff_longitude,omitempty"`
	DropoffName      string  `json:"dropoff_name,omitempty"`
	DistanceKm       float64 `json:"distance_km,omitempty"`
	DurationMinutes  float64 `json:"duration_minutes,omitempty"`
	DriverName       string  `json:"driver_name,omitempty"`
	VehicleType      string  `json:"vehicle_type,omitempty"`
	PlateNumber      string  `json:"plate_number,omitempty"`
	DriverRating     float64 `json:"driver_rating,omitempty"`
	CompletedAt      *string `json:"completed_at,omitempty"`
}
type Bid struct {
	ID           int    `json:"id"`
	RideID       int    `json:"ride_id"`
	DriverID     int    `json:"driver_id"`
	FareCentavos int64  `json:"fare_centavos"`
	Status       string `json:"status"`
}

type BidSession struct {
	ID                  int        `json:"id"`
	PassengerID         int        `json:"passenger_id"`
	RideType            string     `json:"ride_type"`
	PickupLatitude      float64    `json:"pickup_latitude"`
	PickupLongitude     float64    `json:"pickup_longitude"`
	PickupName          string     `json:"pickup_name"`
	DropoffLatitude     float64    `json:"dropoff_latitude"`
	DropoffLongitude    float64    `json:"dropoff_longitude"`
	DropoffName         string     `json:"dropoff_name"`
	DistanceKm          float64    `json:"distance_km"`
	DurationMinutes     float64    `json:"duration_minutes"`
	OfferedFareCentavos int64      `json:"offered_fare_centavos"`
	Status              string     `json:"status"`
	TargetDriverID      *int       `json:"target_driver_id,omitempty"`
	AcceptedDriverID    *int       `json:"accepted_driver_id,omitempty"`
	ExpiresAt           time.Time  `json:"expires_at"`
	CreatedAt           time.Time  `json:"created_at"`
	Offers              []BidOffer `json:"offers,omitempty"`
}

type BidOffer struct {
	ID                   int64     `json:"id"`
	SessionID            int       `json:"session_id"`
	DriverID             int       `json:"driver_id"`
	DriverName           string    `json:"driver_name,omitempty"`
	PlateNumber          string    `json:"plate_number,omitempty"`
	VehicleType          string    `json:"vehicle_type,omitempty"`
	ProposedFareCentavos int64     `json:"proposed_fare_centavos"`
	Status               string    `json:"status"`
	CreatedAt            time.Time `json:"created_at"`
}
