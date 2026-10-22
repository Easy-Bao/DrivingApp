package domain

type Ride struct {
	ID                         int
	BookingReference           string `json:"booking_reference"`
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
	CashSettled                bool
	CancelledBy                *int
	CancellationReason         string
	CancellationResponsibility string
	CancellationDetails        string
	CommissionBPS              *int64
	CommissionAmount           int64
	DriverPayoutAmount         int64
}
