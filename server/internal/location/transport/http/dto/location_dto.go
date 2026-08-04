package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"

type RouteRequest struct {
	Origin      domain.Coordinates `json:"origin"`
	Destination domain.Coordinates `json:"destination"`
}
