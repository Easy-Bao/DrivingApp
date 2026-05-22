pub struct RustPlaceResult {
    pub id: String,
    pub name: String,
    pub full_address: String,
    pub latitude: f64,
    pub longitude: f64,
    pub category: Option<String>,
    pub distance_km: Option<f64>,
}

pub struct RustRouteResult {
    pub polyline_points: Vec<CoordPair>,
    pub distance_km: f64,
    pub duration_seconds: f64,
    pub summary: String,
}

pub struct CoordPair {
    pub lng: f64,
    pub lat: f64,
}
