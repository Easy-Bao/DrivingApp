//! Driver matching data models.
//!
//! Represents nearby drivers discovered by the matching algorithm.
//! Currently populated with randomized mock data, designed so swapping
//! to a real data source only requires changing `driver_service.rs`.

/// A nearby driver available for ride matching.
/// Returned to Flutter as a selectable list item.
pub struct NearbyDriver {
    /// Unique driver identifier.
    pub id: String,
    /// Driver's display name.
    pub name: String,
    /// Vehicle type (e.g., "Motorcycle", "Habal-Habal").
    pub vehicle_type: String,
    /// Vehicle plate number (e.g., "ABC-1234").
    pub plate_number: String,
    /// Driver's average rating (1.0–5.0).
    pub rating: f64,
    /// Driver's current latitude.
    pub lat: f64,
    /// Driver's current longitude.
    pub lng: f64,
    /// Distance from the passenger in kilometers.
    pub distance_km: f64,
    /// Estimated time of arrival in minutes.
    pub eta_minutes: f64,
    /// Composite ranking score (lower is better).
    /// Calculated as: 0.5×distance + 0.3×(5.0-rating) + 0.2×eta
    pub score: f64,
}
