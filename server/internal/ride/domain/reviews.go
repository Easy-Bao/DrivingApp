package domain

type Review struct {
	ID            int     `json:"id"`
	RideID        int     `json:"ride_id"`
	DriverID      int     `json:"driver_id"`
	PassengerID   int     `json:"passenger_id"`
	PassengerName string  `json:"passenger_name,omitempty"`
	Rating        float64 `json:"rating"`
	Comment       string  `json:"comment,omitempty"`
	CreatedAt     string  `json:"created_at"`
}

type PassengerReview struct {
	ID          int     `json:"id"`
	RideID      int     `json:"ride_id"`
	DriverID    int     `json:"driver_id"`
	PassengerID int     `json:"passenger_id"`
	Rating      float64 `json:"rating"`
	Comment     string  `json:"comment,omitempty"`
	CreatedAt   string  `json:"created_at"`
}
