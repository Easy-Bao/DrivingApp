use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxGeocodingResponse {
    pub features: Vec<MapboxFeature>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxFeature {
    pub id: Option<String>,
    pub text: Option<String>,
    pub place_name: Option<String>,
    pub center: Vec<f64>,
    pub properties: Option<MapboxProperties>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxProperties {
    pub category: Option<String>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxDirectionsResponse {
    pub routes: Vec<MapboxRoute>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxRoute {
    pub distance: f64,
    pub duration: f64,
    pub geometry: MapboxGeometry,
    pub legs: Option<Vec<MapboxLeg>>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxGeometry {
    pub coordinates: Vec<Vec<f64>>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxLeg {
    pub summary: Option<String>,
}

/// A geocoded place result.
pub struct RustPlaceResult {
    pub id: String,
    pub name: String,
    pub full_address: String,
    pub latitude: f64,
    pub longitude: f64,
    pub category: Option<String>,
    pub distance_km: Option<f64>,
}

/// A route/directions result.
pub struct RustRouteResult {
    pub polyline_points: Vec<CoordPair>,
    pub distance_km: f64,
    pub duration_seconds: f64,
    pub summary: String,
}

/// A coordinate pair
pub struct CoordPair {
    pub lng: f64,
    pub lat: f64,
}
