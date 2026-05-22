//! Route sequence optimization service.

use crate::models::route_models::{RouteSequenceResult, Waypoint};
use crate::shared::math::haversine_distance;

/// Calculate the optimal route sequence using a TSP search with pickup-before-dropoff constraints.
pub fn calculate_optimal_route(
    start_lat: f64,
    start_lng: f64,
    waypoints: Vec<Waypoint>,
) -> RouteSequenceResult {
    if waypoints.is_empty() {
        return RouteSequenceResult {
            optimal_sequence: Vec::new(),
            total_distance_km: 0.0,
        };
    }

    let mut best_sequence = waypoints.clone();
    let mut min_distance = f64::MAX;

    // Generate permutations
    let mut indices: Vec<usize> = (0..waypoints.len()).collect();
    let mut permutations = Vec::new();
    permute(&mut indices, 0, &mut permutations);

    for perm in permutations {
        // Build sequence for this permutation
        let candidate: Vec<Waypoint> = perm.iter().map(|&idx| waypoints[idx].clone()).collect();

        // Validate pickup-before-dropoff constraint
        if is_valid_sequence(&candidate) {
            // Compute total distance starting from start_lat/lng
            let mut total_dist = 0.0;
            let mut current_lat = start_lat;
            let mut current_lng = start_lng;

            for wp in &candidate {
                total_dist += haversine_distance(current_lat, current_lng, wp.lat, wp.lng);
                current_lat = wp.lat;
                current_lng = wp.lng;
            }

            if total_dist < min_distance {
                min_distance = total_dist;
                best_sequence = candidate;
            }
        }
    }

    RouteSequenceResult {
        optimal_sequence: best_sequence,
        total_distance_km: (min_distance * 100.0).round() / 100.0,
    }
}

// Recursive permutation helper
fn permute(indices: &mut Vec<usize>, start: usize, result: &mut Vec<Vec<usize>>) {
    if start == indices.len() {
        result.push(indices.clone());
        return;
    }
    for i in start..indices.len() {
        indices.swap(start, i);
        permute(indices, start + 1, result);
        indices.swap(start, i); // backtrack
    }
}

// Constraint validator: Pickup must appear before dropoff for each passenger_id
fn is_valid_sequence(seq: &[Waypoint]) -> bool {
    for (i, wp) in seq.iter().enumerate() {
        if !wp.is_pickup {
            let found_pickup = seq[0..i]
                .iter()
                .any(|prev_wp| prev_wp.passenger_id == wp.passenger_id && prev_wp.is_pickup);
            if !found_pickup {
                return false;
            }
        }
    }
    true
}
