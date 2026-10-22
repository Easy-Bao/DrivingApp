package http

type BidSessionRequest struct {
	PickupLatitude   float64 `json:"pickup_latitude"`
	PickupLongitude  float64 `json:"pickup_longitude"`
	PickupName       string  `json:"pickup_name"`
	DropoffLatitude  float64 `json:"dropoff_latitude"`
	DropoffLongitude float64 `json:"dropoff_longitude"`
	DropoffName      string  `json:"dropoff_name"`
	PassengerNote    string  `json:"passenger_note"`
	DistanceKm       float64 `json:"distance_km"`
	DurationMinutes  float64 `json:"duration_minutes"`
	TargetDriverID   *int    `json:"target_driver_id"`
	CustomFareAmount *int64  `json:"custom_fare"`
}

type BidOfferRequest struct {
	DriverName         string  `json:"driver_name"`
	PlateNumber        string  `json:"plate_number"`
	VehicleType        string  `json:"vehicle_type"`
	ProposedFareAmount int64   `json:"proposed_fare"`
	OfferPrice         float64 `json:"offer_price"`
}
