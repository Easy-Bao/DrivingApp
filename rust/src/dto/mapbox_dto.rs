//! Mapbox API response deserialization structs.
//!
//! These DTOs map directly to the JSON returned by Mapbox's Geocoding
//! and Directions APIs. They are `pub(crate)` — internal only, never
//! exposed to Flutter.

use serde::Deserialize;

/// Top-level response from Mapbox Geocoding v5 API.
#[derive(Debug, Deserialize)]
pub(crate) struct MapboxGeocodingResponse {
    pub features: Vec<MapboxFeature>,
}

/// A single geocoding feature (place result) from Mapbox.
#[derive(Debug, Deserialize)]
pub(crate) struct MapboxFeature {
    pub id: Option<String>,
    /// Short place name (e.g., "Gaisano Mall").
    pub text: Option<String>,
    /// Full formatted address string.
    pub place_name: Option<String>,
    /// Coordinates as [longitude, latitude].
    pub center: Vec<f64>,
    pub properties: Option<MapboxProperties>,
}

/// Optional properties attached to a Mapbox feature.
#[derive(Debug, Deserialize)]
pub(crate) struct MapboxProperties {
    pub category: Option<String>,
}

/// Top-level response from Mapbox Directions v5 API.
#[derive(Debug, Deserialize)]
pub(crate) struct MapboxDirectionsResponse {
    pub routes: Vec<MapboxRoute>,
}

/// A single route from Mapbox Directions.
#[derive(Debug, Deserialize)]
pub(crate) struct MapboxRoute {
    /// Total distance in meters.
    pub distance: f64,
    /// Total duration in seconds.
    pub duration: f64,
    /// GeoJSON geometry with coordinate array.
    pub geometry: MapboxGeometry,
    pub legs: Option<Vec<MapboxLeg>>,
}

/// GeoJSON geometry containing the route polyline coordinates.
#[derive(Debug, Deserialize)]
pub(crate) struct MapboxGeometry {
    /// Each entry is [longitude, latitude].
    pub coordinates: Vec<Vec<f64>>,
}

/// A single leg within a Mapbox route.
#[derive(Debug, Deserialize)]
pub(crate) struct MapboxLeg {
    pub summary: Option<String>,
}
