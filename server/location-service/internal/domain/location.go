package domain

import "time"

type Point struct {
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lng"`
}

type BoundingBox struct {
	MinLat float64 `json:"min_lat"`
	MaxLat float64 `json:"max_lat"`
	MinLng float64 `json:"min_lng"`
	MaxLng float64 `json:"max_lng"`
}

type Place struct {
	ID         string  `json:"id"`
	Name       string  `json:"name"`
	Address    string  `json:"address"`
	Category   string  `json:"category"`
	Latitude   float64 `json:"lat"`
	Longitude  float64 `json:"lng"`
	DistanceKm float64 `json:"distance_km,omitempty"`
}

type Route struct {
	OriginLat   float64   `json:"originLat"`
	OriginLng   float64   `json:"originLng"`
	DestLat     float64   `json:"destLat"`
	DestLng     float64   `json:"destLng"`
	DistanceKm  float64   `json:"distanceKm"`
	DurationMin float64   `json:"durationMin"`
	Polyline    string    `json:"polyline"`
	Waypoints   [][]float64 `json:"waypoints"`
}

type LocationUpdateEvent struct {
	ID        string    `json:"id"`
	DriverID  string    `json:"driver_id"`
	Latitude  float64   `json:"lat"`
	Longitude float64   `json:"lng"`
	Timestamp time.Time `json:"timestamp"`
}
