/// Configuration for fare calculation.
/// Pass custom values for different vehicle types or surge periods.
pub struct FareConfig {
    pub base_fare: f64,
    pub per_km_rate: f64,
    pub per_minute_rate: f64,
    pub surge_multiplier: f64,
    pub minimum_fare: f64,
}

/// Itemized result of a fare calculation.
pub struct FareResult {
    pub base_fare: f64,
    pub distance_charge: f64,
    pub time_charge: f64,
    pub surge_charge: f64,
    pub total_fare: f64,
}

/// A single cell in the surge demand heatmap.
/// Rendered as a colored overlay on the driver's map.
#[derive(Debug, Clone)]
pub struct HeatmapCell {
    pub lat: f64,
    pub lng: f64,
    pub intensity: f64,
}
