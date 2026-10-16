package domain

type OnlineDriver struct {
	ID                    int
	UserID                int
	Name                  string
	VehicleType           string
	PlateNumber           string
	Rating                float64
	OnboardPassengerCount int
}

type PublicDriverSummary struct {
	ID          int
	Name        string
	VehicleType string
	Rating      float64
}
