package domain

type Ride struct {
	ID           int    `json:"id"`
	PassengerID  int    `json:"passenger_id"`
	DriverID     *int   `json:"driver_id,omitempty"`
	Status       string `json:"status"`
	FareCentavos int64  `json:"fare_centavos"`
}
type Bid struct {
	ID           int    `json:"id"`
	RideID       int    `json:"ride_id"`
	DriverID     int    `json:"driver_id"`
	FareCentavos int64  `json:"fare_centavos"`
	Status       string `json:"status"`
}
