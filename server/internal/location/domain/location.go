package domain

import (
	"fmt"
	"math"
	"slices"
)

// Coordinates identifies a point in decimal degrees. Callers should validate
// it before sending the value to a provider.
type Coordinates struct {
	Latitude  float64
	Longitude float64
}

// Valid reports whether both coordinates are finite and within geographic
// latitude and longitude bounds.
func (coordinates Coordinates) Valid() bool {
	return isFiniteInRange(coordinates.Latitude, -90, 90) &&
		isFiniteInRange(coordinates.Longitude, -180, 180)
}

func isFiniteInRange(value, minimum, maximum float64) bool {
	return !math.IsNaN(value) &&
		!math.IsInf(value, 0) &&
		value >= minimum &&
		value <= maximum
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

// RouteOptions controls route optimization, profile selection, and excluded
// map points.
type RouteOptions struct {
	Preference    RoutePreference
	Profile       RouteProfile
	ExcludePoints []Coordinates
}

// Normalize fills defaults and rejects unsupported route options or invalid
// exclusion points.
func (options RouteOptions) Normalize() (RouteOptions, error) {
	options.ExcludePoints = slices.Clone(options.ExcludePoints)
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
	for _, point := range options.ExcludePoints {
		if !point.Valid() {
			return RouteOptions{}, fmt.Errorf("route exclusion contains invalid coordinates")
		}
	}
	return options, nil
}

type Place struct {
	ID             string
	Name           string
	Address        string
	Category       string
	Latitude       float64
	Longitude      float64
	DistanceKm     float64
	MatchType      string
	DistanceMeters float64
	Confidence     float64
	Context        map[string]string
}

type Route struct {
	Origin      Coordinates
	Destination Coordinates
	Preference  string
	Profile     string
	DistanceKm  float64
	DurationMin float64
	Polyline    [][]float64
}

type Matrix struct {
	DistancesKm  []float64
	DurationsMin []float64
}
