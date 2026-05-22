//! Fare engine FFI bridge API.

use crate::models::fare_models::{FareConfig, FareResult, HeatmapCell};
use crate::models::route_models::{RouteSequenceResult, Waypoint};
use crate::services;

/// Compute the fare for a ride given distance, duration, and pricing config.
pub fn compute_fare(distance_km: f64, duration_minutes: f64, config: FareConfig) -> FareResult {
    services::fare_service::compute_fare(distance_km, duration_minutes, config)
}

/// Compute fare with default BaoBao pricing.
pub fn compute_fare_default(distance_km: f64, duration_minutes: f64) -> FareResult {
    services::fare_service::compute_fare_default(distance_km, duration_minutes)
}

/// Calculate surge heatmap grid using Kernel Density Estimation (KDE)
pub fn calculate_surge_heatmap(
    center_lat: f64,
    center_lng: f64,
    grid_size: i32,
    cell_size_degrees: f64,
    request_lats: Vec<f64>,
    request_lngs: Vec<f64>,
) -> Vec<HeatmapCell> {
    services::heatmap_service::calculate_surge_heatmap(
        center_lat,
        center_lng,
        grid_size,
        cell_size_degrees,
        request_lats,
        request_lngs,
    )
}

/// Calculate the optimal route sequence using a TSP search with pickup-before-dropoff constraints.
pub fn calculate_optimal_route(
    start_lat: f64,
    start_lng: f64,
    waypoints: Vec<Waypoint>,
) -> RouteSequenceResult {
    services::route_service::calculate_optimal_route(start_lat, start_lng, waypoints)
}
