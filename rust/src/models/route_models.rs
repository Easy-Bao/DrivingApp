//! Route optimization data models.
//!
//! Used by the TSP-based route optimizer for multi-stop rides.

/// A single stop (pickup or dropoff) in a multi-passenger route.
#[derive(Debug, Clone)]
pub struct Waypoint {
    pub id: String,
    /// Human-readable label (e.g., "Juan's Pickup").
    pub name: String,
    pub lat: f64,
    pub lng: f64,
    /// True for pickup stops, false for dropoff stops.
    pub is_pickup: bool,
    /// Links pickups and dropoffs for the same passenger.
    pub passenger_id: String,
}

/// Result of the optimal route calculation.
#[derive(Debug, Clone)]
pub struct RouteSequenceResult {
    /// Waypoints in the computed optimal visit order.
    pub optimal_sequence: Vec<Waypoint>,
    /// Total route distance in kilometers.
    pub total_distance_km: f64,
}
