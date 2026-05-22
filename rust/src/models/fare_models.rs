//! Fare calculation data models.
//!
//! Used by the fare engine to configure pricing and return
//! itemized fare breakdowns to the Flutter UI.

/// Configuration for fare calculation.
/// Pass custom values for different vehicle types or surge periods.
pub struct FareConfig {
    /// Fixed starting cost (e.g., ₱20.00).
    pub base_fare: f64,
    /// Cost per kilometer driven (e.g., ₱10.00).
    pub per_km_rate: f64,
    /// Cost per minute of travel time (e.g., ₱1.50).
    pub per_minute_rate: f64,
    /// Multiplier applied during high-demand periods (1.0 = no surge).
    pub surge_multiplier: f64,
    /// Floor price — fare never goes below this (e.g., ₱25.00).
    pub minimum_fare: f64,
}

/// Itemized result of a fare calculation.
/// All monetary values are in Philippine Peso (₱).
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
    /// Surge intensity as a multiplier:
    /// 1.0 = normal, 1.5 = 50% surge, 2.0 = 100% surge.
    pub intensity: f64,
}
