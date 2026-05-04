// =============================================================================
// MAP API — Rust-powered Mapbox API computation layer
// =============================================================================
//
// All HTTP requests, JSON parsing, and math computations for map operations
// are handled natively in Rust for maximum performance.
//
// This is the entrypoint called from Dart via flutter_rust_bridge.
// =============================================================================

use crate::core::models::{RustPlaceResult, RustRouteResult};
use crate::services::mapbox;
use crate::utils::math;

// ─── Haversine distance ──────────────────────────────────────────────────────

/// Calculate the great-circle distance between two points in kilometers.
/// Pure math — no IO, no allocation, maximum speed.
pub fn haversine_distance(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
    math::haversine_distance(lat1, lng1, lat2, lng2)
}

// ─── Forward Geocoding ───────────────────────────────────────────────────────

/// Search for places using Mapbox Geocoding API.
pub async fn search_places(
    token: String,
    query: String,
    proximity_lat: Option<f64>,
    proximity_lng: Option<f64>,
    user_lat: Option<f64>,
    user_lng: Option<f64>,
) -> anyhow::Result<Vec<RustPlaceResult>> {
    mapbox::search_places(
        &token,
        &query,
        proximity_lat,
        proximity_lng,
        user_lat,
        user_lng,
    )
    .await
}

// ─── Reverse Geocoding ───────────────────────────────────────────────────────

/// Get place info from coordinates using Mapbox Geocoding API.
pub async fn reverse_geocode(
    token: String,
    lat: f64,
    lng: f64,
) -> anyhow::Result<Option<RustPlaceResult>> {
    mapbox::reverse_geocode(&token, lat, lng).await
}

// ─── Directions / Routing ────────────────────────────────────────────────────

/// Get a driving route between two points.
pub async fn get_route(
    token: String,
    origin_lat: f64,
    origin_lng: f64,
    dest_lat: f64,
    dest_lng: f64,
) -> anyhow::Result<Option<RustRouteResult>> {
    mapbox::get_route(&token, origin_lat, origin_lng, dest_lat, dest_lng).await
}
