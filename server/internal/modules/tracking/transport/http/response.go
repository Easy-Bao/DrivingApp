package http

import (
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/domain"
)

type DriverLocationResponse struct {
	DriverID   string    `json:"driver_id"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Heading    float64   `json:"heading,omitempty"`
	Speed      float64   `json:"speed,omitempty"`
	ObservedAt time.Time `json:"observed_at"`
}

func NewDriverLocationResponse(point domain.DriverPoint) DriverLocationResponse {
	return DriverLocationResponse{
		DriverID:   point.DriverID,
		Latitude:   point.Latitude,
		Longitude:  point.Longitude,
		Heading:    point.Heading,
		Speed:      point.Speed,
		ObservedAt: point.ObservedAt,
	}
}

func NewDriverLocationResponses(points []domain.DriverPoint) []DriverLocationResponse {
	if points == nil {
		return nil
	}

	responses := make([]DriverLocationResponse, 0, len(points))
	for _, point := range points {
		responses = append(responses, NewDriverLocationResponse(point))
	}
	return responses
}
