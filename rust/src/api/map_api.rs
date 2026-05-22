//! Mapbox API wrapper FFI bridge API.

use crate::infrastructure::mapbox_client;
use crate::models::map_models::{RustPlaceResult, RustRouteResult};
use crate::shared::math;

/// Calculate the great-circle distance between two points in kilometers.
pub fn haversine_distance(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
    math::haversine_distance(lat1, lng1, lat2, lng2)
}

/// Search for places using Mapbox Geocoding API.
pub async fn search_places(
    token: String,
    query: String,
    proximity_lat: Option<f64>,
    proximity_lng: Option<f64>,
    user_lat: Option<f64>,
    user_lng: Option<f64>,
) -> anyhow::Result<Vec<RustPlaceResult>> {
    mapbox_client::search_places(
        &token,
        &query,
        proximity_lat,
        proximity_lng,
        user_lat,
        user_lng,
    )
    .await
}

/// Get place info from coordinates using Mapbox Geocoding API.
pub async fn reverse_geocode(
    token: String,
    lat: f64,
    lng: f64,
) -> anyhow::Result<Option<RustPlaceResult>> {
    mapbox_client::reverse_geocode(&token, lat, lng).await
}

/// Get a driving route between two points.
pub async fn get_route(
    token: String,
    origin_lat: f64,
    origin_lng: f64,
    dest_lat: f64,
    dest_lng: f64,
) -> anyhow::Result<Option<RustRouteResult>> {
    mapbox_client::get_route(&token, origin_lat, origin_lng, dest_lat, dest_lng).await
}

/// Extract all dynamic Points of Interest from Mapbox vector tiles within a radius
pub async fn get_nearby_pois(
    token: String,
    lat: f64,
    lng: f64,
) -> anyhow::Result<Vec<RustPlaceResult>> {
    // Default radius to 2000 meters (2km) based on user request
    mapbox_client::get_nearby_pois(&token, lat, lng, 2000).await
}
