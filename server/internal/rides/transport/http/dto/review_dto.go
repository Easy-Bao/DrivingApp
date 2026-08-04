package dto

type ReviewRequest struct {
	PassengerName string  `json:"passenger_name"`
	Rating        float64 `json:"rating"`
	Comment       string  `json:"comment"`
}
