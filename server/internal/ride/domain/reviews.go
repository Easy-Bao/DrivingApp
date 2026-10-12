package domain

type Review struct {
	ID            int
	RideID        int
	DriverID      int
	PassengerID   int
	PassengerName string
	Rating        float64
	Comment       string
	CreatedAt     string
}

type PassengerReview struct {
	ID          int
	RideID      int
	DriverID    int
	PassengerID int
	Rating      float64
	Comment     string
	CreatedAt   string
}
