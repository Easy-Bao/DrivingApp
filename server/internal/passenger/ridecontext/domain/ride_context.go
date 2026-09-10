package domain

import "math"

type Coordinates struct {
	Latitude  float64
	Longitude float64
}

func (coordinates Coordinates) Valid() bool {
	return !math.IsNaN(coordinates.Latitude) &&
		!math.IsInf(coordinates.Latitude, 0) &&
		!math.IsNaN(coordinates.Longitude) &&
		!math.IsInf(coordinates.Longitude, 0) &&
		coordinates.Latitude >= -90 && coordinates.Latitude <= 90 &&
		coordinates.Longitude >= -180 && coordinates.Longitude <= 180
}

type RecentDestination struct {
	Status    string
	Title     string
	Subtitle  string
	Latitude  float64
	Longitude float64
}

type RecentLocation struct {
	Title     string
	Subtitle  string
	Latitude  float64
	Longitude float64
}

type RideContextSnapshot struct {
	CurrentAddress  string
	RecentLocations []RecentLocation
}
