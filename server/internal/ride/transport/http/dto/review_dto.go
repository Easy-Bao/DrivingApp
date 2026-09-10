// Package dto contains the ride HTTP request and response contracts.
package dto

type ReviewRequest struct {
	RideID  int     `json:"ride_id"`
	Rating  float64 `json:"rating"`
	Comment string  `json:"comment"`
}
