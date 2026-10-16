package http

import (
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
	trackingdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
)

type PlaceResponse struct {
	ID             string            `json:"id"`
	Name           string            `json:"name"`
	Address        string            `json:"address"`
	Category       string            `json:"category"`
	Latitude       float64           `json:"lat"`
	Longitude      float64           `json:"lng"`
	DistanceKm     float64           `json:"distance_km,omitempty"`
	MatchType      string            `json:"match_type,omitempty"`
	DistanceMeters float64           `json:"distance_meters,omitempty"`
	Confidence     float64           `json:"confidence,omitempty"`
	Context        map[string]string `json:"context,omitempty"`
}

type RouteResponse struct {
	Origin      Coordinate  `json:"origin"`
	Destination Coordinate  `json:"destination"`
	Preference  string      `json:"preference"`
	Profile     string      `json:"profile"`
	DistanceKm  float64     `json:"distance_km"`
	DurationMin float64     `json:"duration_min"`
	Polyline    [][]float64 `json:"polyline"`
}

type MatrixResponse struct {
	DistancesKm  []float64 `json:"distances_km"`
	DurationsMin []float64 `json:"durations_min"`
}

func NewPlaceResponse(place *domain.Place) *PlaceResponse {
	if place == nil {
		return nil
	}
	return &PlaceResponse{
		ID:             place.ID,
		Name:           place.Name,
		Address:        place.Address,
		Category:       place.Category,
		Latitude:       place.Latitude,
		Longitude:      place.Longitude,
		DistanceKm:     place.DistanceKm,
		MatchType:      place.MatchType,
		DistanceMeters: place.DistanceMeters,
		Confidence:     place.Confidence,
		Context:        place.Context,
	}
}

func NewPlaceResponses(places []domain.Place) []PlaceResponse {
	if places == nil {
		return nil
	}
	responses := make([]PlaceResponse, 0, len(places))
	for index := range places {
		responses = append(responses, *NewPlaceResponse(&places[index]))
	}
	return responses
}

func NewRouteResponse(route *domain.Route) *RouteResponse {
	if route == nil {
		return nil
	}
	return &RouteResponse{
		Origin:      NewCoordinate(route.Origin),
		Destination: NewCoordinate(route.Destination),
		Preference:  route.Preference,
		Profile:     route.Profile,
		DistanceKm:  route.DistanceKm,
		DurationMin: route.DurationMin,
		Polyline:    route.Polyline,
	}
}

func NewMatrixResponse(matrix *domain.Matrix) *MatrixResponse {
	if matrix == nil {
		return nil
	}
	return &MatrixResponse{DistancesKm: matrix.DistancesKm, DurationsMin: matrix.DurationsMin}
}

type DriverLocationResponse struct {
	DriverID   string    `json:"driver_id"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Heading    float64   `json:"heading,omitempty"`
	Speed      float64   `json:"speed,omitempty"`
	ObservedAt time.Time `json:"observed_at"`
}

func NewDriverLocationResponse(point trackingdomain.DriverPoint) DriverLocationResponse {
	return DriverLocationResponse{
		DriverID:   point.DriverID,
		Latitude:   point.Latitude,
		Longitude:  point.Longitude,
		Heading:    point.Heading,
		Speed:      point.Speed,
		ObservedAt: point.ObservedAt,
	}
}

func NewDriverLocationResponses(points []trackingdomain.DriverPoint) []DriverLocationResponse {
	if points == nil {
		return nil
	}

	responses := make([]DriverLocationResponse, 0, len(points))
	for _, point := range points {
		responses = append(responses, NewDriverLocationResponse(point))
	}
	return responses
}
