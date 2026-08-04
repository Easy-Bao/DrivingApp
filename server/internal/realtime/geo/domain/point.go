package domain

import "context"

type DriverPoint struct {
	DriverID  string  `json:"driver_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}
type Repository interface {
	Upsert(ctx context.Context, point DriverPoint) error
	Nearby(ctx context.Context, latitude, longitude float64, radiusKm float64) ([]DriverPoint, error)
}
