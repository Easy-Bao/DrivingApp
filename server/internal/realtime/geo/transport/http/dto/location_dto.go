package dto

type LocationUpdate struct {
	DriverID  string  `json:"driver_id"`
	LegacyID  string  `json:"driverId"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Lat       float64 `json:"lat"`
	Lng       float64 `json:"lng"`
}

type PassengerLocationUpdate struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Lat       float64 `json:"lat"`
	Lng       float64 `json:"lng"`
}
