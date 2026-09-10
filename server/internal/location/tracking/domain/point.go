package domain

import "errors"

var (
	ErrInvalidLocation           = errors.New("invalid location")
	ErrRideAccessDenied          = errors.New("ride location access denied")
	ErrRideAssignmentUnavailable = errors.New("ride location authorization is unavailable")
)

type DriverPoint struct {
	DriverID  string  `json:"driver_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Heading   float64 `json:"heading,omitempty"`
	Speed     float64 `json:"speed,omitempty"`
}
