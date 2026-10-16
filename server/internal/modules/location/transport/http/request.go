package http

import (
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
)

type Coordinate struct {
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lng"`
}

func (coordinate Coordinate) ToDomain() domain.Coordinates {
	return domain.Coordinates{Latitude: coordinate.Latitude, Longitude: coordinate.Longitude}
}

func NewCoordinate(coordinates domain.Coordinates) Coordinate {
	return Coordinate{Latitude: coordinates.Latitude, Longitude: coordinates.Longitude}
}

type RouteRequest struct {
	Origin        Coordinate             `json:"origin"`
	Destination   Coordinate             `json:"destination"`
	Preference    domain.RoutePreference `json:"preference,omitempty"`
	Profile       domain.RouteProfile    `json:"profile,omitempty"`
	ExcludePoints []Coordinate           `json:"exclude_points,omitempty"`
}

type MatrixRequest struct {
	Origin       Coordinate   `json:"origin"`
	Destinations []Coordinate `json:"destinations"`
}

func (request RouteRequest) Options() (domain.RouteOptions, error) {
	var excludePoints []domain.Coordinates
	if request.ExcludePoints != nil {
		excludePoints = make([]domain.Coordinates, 0, len(request.ExcludePoints))
		for _, point := range request.ExcludePoints {
			excludePoints = append(excludePoints, point.ToDomain())
		}
	}
	return (domain.RouteOptions{
		Preference:    request.Preference,
		Profile:       request.Profile,
		ExcludePoints: excludePoints,
	}).Normalize()
}

func (request MatrixRequest) DomainOrigin() domain.Coordinates {
	return request.Origin.ToDomain()
}

func (request MatrixRequest) DomainDestinations() []domain.Coordinates {
	if request.Destinations == nil {
		return nil
	}
	destinations := make([]domain.Coordinates, 0, len(request.Destinations))
	for _, destination := range request.Destinations {
		destinations = append(destinations, destination.ToDomain())
	}
	return destinations
}

type LocationUpdate struct {
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Heading    float64   `json:"heading"`
	Speed      float64   `json:"speed"`
	ObservedAt time.Time `json:"observed_at"`
}

type PassengerLocationUpdate struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}
