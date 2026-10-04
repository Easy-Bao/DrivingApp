package dto

type ReviewRequest struct {
	RideID  int     `json:"ride_id"`
	Rating  float64 `json:"rating"`
	Comment string  `json:"comment"`
}

type SafetyReportRequest struct {
	Category    string `json:"category"`
	Description string `json:"description"`
}
