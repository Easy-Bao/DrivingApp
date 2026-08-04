package domain

type Coordinates struct {
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lng"`
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
	Origin      Coordinates `json:"origin"`
	Destination Coordinates `json:"destination"`
	DistanceKm  float64     `json:"distance_km"`
	DurationMin float64     `json:"duration_min"`
	Polyline    [][]float64 `json:"polyline"`
}

type Matrix struct {
	DistancesKm  []float64 `json:"distances_km"`
	DurationsMin []float64 `json:"durations_min"`
}
