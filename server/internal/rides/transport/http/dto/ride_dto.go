package dto

type CreateRideRequest struct {
	FareCentavos     int64   `json:"fare_centavos"`
	RideType         string  `json:"ride_type"`
	PickupLatitude   float64 `json:"pickup_latitude"`
	PickupLongitude  float64 `json:"pickup_longitude"`
	PickupName       string  `json:"pickup_name"`
	DropoffLatitude  float64 `json:"dropoff_latitude"`
	DropoffLongitude float64 `json:"dropoff_longitude"`
	DropoffName      string  `json:"dropoff_name"`
	DistanceKm       float64 `json:"distance_km"`
	DurationMinutes  float64 `json:"duration_minutes"`
}
type SubmitBidRequest struct {
	FareCentavos int64 `json:"fare_centavos"`
}
type FareEstimateRequest struct {
	DistanceKm      float64 `json:"distance_km"`
	DurationMinutes float64 `json:"duration_minutes"`
}
type FinalFareRequest struct {
	DistanceKm      float64 `json:"distance_km"`
	DurationMinutes float64 `json:"duration_minutes"`
	CommissionBPS   int64   `json:"commission_bps"`
}

type StatusRequest struct {
	Status string `json:"status"`
}

type BidSessionRequest struct {
	RideType         string  `json:"ride_type"`
	PickupLatitude   float64 `json:"pickup_latitude"`
	PickupLongitude  float64 `json:"pickup_longitude"`
	PickupName       string  `json:"pickup_name"`
	DropoffLatitude  float64 `json:"dropoff_latitude"`
	DropoffLongitude float64 `json:"dropoff_longitude"`
	DropoffName      string  `json:"dropoff_name"`
	DistanceKm       float64 `json:"distance_km"`
	DurationMinutes  float64 `json:"duration_minutes"`
	TargetDriverID   *int    `json:"target_driver_id"`
}

type BidOfferRequest struct {
	DriverName           string  `json:"driver_name"`
	PlateNumber          string  `json:"plate_number"`
	VehicleType          string  `json:"vehicle_type"`
	ProposedFareCentavos int64   `json:"proposed_fare_centavos"`
	OfferPrice           float64 `json:"offer_price"`
}
