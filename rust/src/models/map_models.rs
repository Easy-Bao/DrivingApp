//! Map and geocoding data models.
//!
//! Bridge-visible structs returned by the Mapbox geocoding and
//! directions API wrappers.

/// A geocoded place result returned to Flutter.
pub struct RustPlaceResult {
    pub id: String,
    /// Short display name (e.g., "Gaisano Mall").
    pub name: String,
    /// Full formatted address string.
    pub full_address: String,
    pub latitude: f64,
    pub longitude: f64,
    /// Place category (e.g., "restaurant", "gas_station").
    pub category: Option<String>,
    /// Distance from the user's current position in kilometers.
    pub distance_km: Option<f64>,
}

/// A driving route result returned to Flutter.
pub struct RustRouteResult {
    /// Ordered list of coordinate pairs forming the route polyline.
    pub polyline_points: Vec<CoordPair>,
    /// Total route distance in kilometers.
    pub distance_km: f64,
    /// Total estimated travel time in seconds.
    pub duration_seconds: f64,
    /// Human-readable route summary (e.g., street names).
    pub summary: String,
}

/// A single coordinate pair [longitude, latitude].
pub struct CoordPair {
    pub lng: f64,
    pub lat: f64,
}
