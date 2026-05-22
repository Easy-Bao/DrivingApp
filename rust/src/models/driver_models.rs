/// A nearby driver available for ride matching.
/// Returned to Flutter as a selectable list item.
pub struct NearbyDriver {
    pub id: String,
    pub name: String,
    pub vehicle_type: String,
    pub plate_number: String,
    pub rating: f64,
    pub lat: f64,
    pub lng: f64,
    pub distance_km: f64,
    pub eta_minutes: f64,
    pub score: f64,
}
