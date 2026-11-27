package mapbox

import (
	"encoding/json"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/places/domain"
)

type featureResponse struct {
	Features []feature `json:"features"`
}

type feature struct {
	ID         string `json:"id"`
	Properties struct {
		MapboxID       string          `json:"mapbox_id"`
		Name           string          `json:"name"`
		PreferredName  string          `json:"name_preferred"`
		FeatureType    string          `json:"feature_type"`
		Address        string          `json:"full_address"`
		ShortAddress   string          `json:"address"`
		PlaceFormatted string          `json:"place_formatted"`
		Category       json.RawMessage `json:"poi_category"`
		Coordinates    struct {
			Latitude  *float64 `json:"latitude"`
			Longitude *float64 `json:"longitude"`
			Accuracy  string   `json:"accuracy"`
		} `json:"coordinates"`
		Context map[string]featureContext `json:"context"`
	} `json:"properties"`
	Geometry struct {
		Coordinates []float64 `json:"coordinates"`
	} `json:"geometry"`
	FeatureType string `json:"feature_type"`
}

type featureContext struct {
	Name string `json:"name"`
}

type categoryResult struct {
	places []domain.Place
	err    error
}

type reverseMatch struct {
	matchType      string
	distanceMeters float64
	confidence     float64
}

type reverseCandidateRank struct {
	stage          int
	prominence     int
	distanceMeters float64
}

type directionsResponse struct {
	Routes []cachedRoute `json:"routes"`
}

type matrixResponse struct {
	Code      string       `json:"code"`
	Distances [][]*float64 `json:"distances"`
	Durations [][]*float64 `json:"durations"`
}

type cachedRoute struct {
	Distance float64 `json:"distance"`
	Duration float64 `json:"duration"`
	Geometry struct {
		Coordinates [][]float64 `json:"coordinates"`
	} `json:"geometry"`
}
