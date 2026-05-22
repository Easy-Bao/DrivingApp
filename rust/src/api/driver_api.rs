//! Driver matching FFI bridge API.

use crate::models::driver_models::NearbyDriver;
use crate::services;

/// Discovers and ranks 5 nearby drivers relative to the passenger's current coordinates.
/// Passes the computation off to the pure Rust driver matching service.
pub fn find_nearby_drivers(passenger_lat: f64, passenger_lng: f64) -> Vec<NearbyDriver> {
    services::driver_service::find_nearby_drivers(passenger_lat, passenger_lng)
}
