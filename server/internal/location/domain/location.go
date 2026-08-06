package domain

import "fmt"

type Coordinates struct {
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lng"`
}

type RoutePreference string

const (
	RoutePreferenceFastest  RoutePreference = "fastest"
	RoutePreferenceShortest RoutePreference = "shortest"
)

type RouteProfile string

const (
	RouteProfileDriving        RouteProfile = "driving"
	RouteProfileDrivingTraffic RouteProfile = "driving-traffic"
)

type RouteOptions struct {
	Preference    RoutePreference
	Profile       RouteProfile
	ExcludePoints []Coordinates
}

func (options RouteOptions) Normalize() (RouteOptions, error) {
	if options.Preference == "" {
		options.Preference = RoutePreferenceFastest
	}
	if options.Profile == "" {
		options.Profile = RouteProfileDriving
	}
	if options.Preference != RoutePreferenceFastest && options.Preference != RoutePreferenceShortest {
		return RouteOptions{}, fmt.Errorf("unsupported route preference %q", options.Preference)
	}
	if options.Profile != RouteProfileDriving && options.Profile != RouteProfileDrivingTraffic {
		return RouteOptions{}, fmt.Errorf("unsupported route profile %q", options.Profile)
	}
	if len(options.ExcludePoints) > 50 {
		return RouteOptions{}, fmt.Errorf("route cannot exclude more than 50 points")
	}
	return options, nil
}

type Place struct {
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

type Route struct {
	Origin      Coordinates `json:"origin"`
	Destination Coordinates `json:"destination"`
	Preference  string      `json:"preference"`
	Profile     string      `json:"profile"`
	DistanceKm  float64     `json:"distance_km"`
	DurationMin float64     `json:"duration_min"`
	Polyline    [][]float64 `json:"polyline"`
}

type Matrix struct {
	DistancesKm  []float64 `json:"distances_km"`
	DurationsMin []float64 `json:"durations_min"`
}
