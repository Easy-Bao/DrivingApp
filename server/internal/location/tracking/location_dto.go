package tracking

import "time"

type LocationUpdate struct {
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Heading    float64   `json:"heading"`
	Speed      float64   `json:"speed"`
	ObservedAt time.Time `json:"observed_at"`
}

type PassengerLocationUpdate struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}
