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
    /// Each entry is [longitude, latitude].
    pub coordinates: Vec<Vec<f64>>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct MapboxLeg {
    pub summary: Option<String>,
}