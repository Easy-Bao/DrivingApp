package http

type CreateRideRequest struct {
	FareAmount int64 `json:"fare_amount"`

	PickupLatitude   float64 `json:"pickup_latitude"`
	PickupLongitude  float64 `json:"pickup_longitude"`
	PickupName       string  `json:"pickup_name"`
	DropoffLatitude  float64 `json:"dropoff_latitude"`
	DropoffLongitude float64 `json:"dropoff_longitude"`
	DropoffName      string  `json:"dropoff_name"`
	DistanceKm       float64 `json:"distance_km"`
	DurationMinutes  float64 `json:"duration_minutes"`
}

type FareEstimateRequest struct {
	DistanceKm           float64  `json:"distance_km"`
	DurationMinutes      float64  `json:"duration_minutes"`
	OriginLatitude       *float64 `json:"origin_latitude"`
	OriginLongitude      *float64 `json:"origin_longitude"`
	DestinationLatitude  *float64 `json:"destination_latitude"`
	DestinationLongitude *float64 `json:"destination_longitude"`
}

type FinalFareRequest struct {
	DistanceKm           float64  `json:"distance_km"`
	DurationMinutes      float64  `json:"duration_minutes"`
	OriginLatitude       *float64 `json:"origin_latitude"`
	OriginLongitude      *float64 `json:"origin_longitude"`
	DestinationLatitude  *float64 `json:"destination_latitude"`
	DestinationLongitude *float64 `json:"destination_longitude"`
}

type StatusRequest struct {
	Status string `json:"status"`
}

type CancellationRequest struct {
	Reason  string `json:"reason"`
	Details string `json:"details"`
}

type EmergencyStopRequest struct {
	Reason  string `json:"reason"`
	Details string `json:"details"`
}

type ArrivalRequest struct {
	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
}

type TripLocationRequest struct {
	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
}

type CashSettlementRequest struct {
	CashReceivedAmount int64  `json:"cash_received_amount"`
	CashChangeAmount   int64  `json:"cash_change_amount"`
	CashOutcome        string `json:"cash_outcome"`
}

type SafetyReportRequest struct {
	Category    string `json:"category"`
	Description string `json:"description"`
}
