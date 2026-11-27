package domain

import "github.com/Easy-Bao/DrivingApp/server/internal/platform/geo"

type Coordinates struct {
	Latitude  float64
	Longitude float64
}

func (coordinates Coordinates) Valid() bool {
	return geo.ValidCoordinates(coordinates.Latitude, coordinates.Longitude)
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
