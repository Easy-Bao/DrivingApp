package domain

import (
	"errors"
	"time"
)

var (
	ErrInvalidLocation           = errors.New("invalid location")
	ErrLocationNotFound          = errors.New("location not found")
	ErrStaleLocation             = errors.New("location timestamp is older than the latest point")
	ErrRideAccessDenied          = errors.New("ride location access denied")
	ErrRideAssignmentUnavailable = errors.New("ride location authorization is unavailable")
	ErrDriverOffline             = errors.New("driver is offline")
	ErrDriverPresenceUnavailable = errors.New("driver presence is unavailable")
)

type DriverPoint struct {
	DriverID   string
	Latitude   float64
	Longitude  float64
	Heading    float64
	Speed      float64
	ObservedAt time.Time
}
