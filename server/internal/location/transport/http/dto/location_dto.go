package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"

type RouteRequest struct {
	Origin        domain.Coordinates     `json:"origin"`
	Destination   domain.Coordinates     `json:"destination"`
	Preference    domain.RoutePreference `json:"preference,omitempty"`
	Profile       domain.RouteProfile    `json:"profile,omitempty"`
	ExcludePoints []domain.Coordinates   `json:"exclude_points,omitempty"`
}

type MatrixRequest struct {
	Origin       domain.Coordinates   `json:"origin"`
	Destinations []domain.Coordinates `json:"destinations"`
}

func (request RouteRequest) Options() (domain.RouteOptions, error) {
	return (domain.RouteOptions{
		Preference:    request.Preference,
		Profile:       request.Profile,
		ExcludePoints: request.ExcludePoints,
	}).Normalize()
}
