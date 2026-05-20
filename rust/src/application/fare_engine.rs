use crate::shared::math::haversine_distance;

/// Configuration for fare calculation.
pub struct FareConfig {
    pub base_fare: f64,
    pub per_km_rate: f64,
    pub per_minute_rate: f64,
    pub surge_multiplier: f64,
    pub minimum_fare: f64,
}

/// Result of a fare calculation.
pub struct FareResult {
    pub base_fare: f64,
    pub distance_charge: f64,
    pub time_charge: f64,
    pub surge_charge: f64,
    pub total_fare: f64,
}

/// Compute the fare for a ride given distance, duration, and pricing config.
///
/// All monetary values are in PHP (₱).
/// The computation applies:
/// Base fare
/// Distance charge = distance_km × per_km_rate
/// Time charge = duration_minutes × per_minute_rate
/// Subtotal = base + distance + time
/// Surge = subtotal × (surge_multiplier - 1.0)
/// Total = subtotal + surge, clamped to minimum_fare
/// Rounded to nearest ₱0.50
pub fn compute_fare(distance_km: f64, duration_minutes: f64, config: FareConfig) -> FareResult {
    let distance_charge = distance_km * config.per_km_rate;
    let time_charge = duration_minutes * config.per_minute_rate;
    let subtotal = config.base_fare + distance_charge + time_charge;

    let surge_charge = if config.surge_multiplier > 1.0 {
        subtotal * (config.surge_multiplier - 1.0)
    } else {
        0.0
    };

    let raw_total = subtotal + surge_charge;
    let enforced_min = if raw_total < config.minimum_fare {
        config.minimum_fare
    } else {
        raw_total
    };

    // Round to nearest ₱0.50
    let total_fare = (enforced_min * 2.0).round() / 2.0;

    FareResult {
        base_fare: config.base_fare,
        distance_charge,
        time_charge,
        surge_charge,
        total_fare,
    }
}

/// Compute fare with default BaoBao pricing.
///
/// Default rates:
/// - Base fare: ₱20.00
/// - Per km: ₱10.00
/// - Per minute: ₱1.50
/// - Surge: 1.0× (no surge)
/// - Minimum: ₱25.00
pub fn compute_fare_default(distance_km: f64, duration_minutes: f64) -> FareResult {
    compute_fare(
        distance_km,
        duration_minutes,
        FareConfig {
            base_fare: 20.0,
            per_km_rate: 10.0,
            per_minute_rate: 1.5,
            surge_multiplier: 1.0,
            minimum_fare: 25.0,
        },
    )
}

#[derive(Debug, Clone)]
pub struct HeatmapCell {
    pub lat: f64,
    pub lng: f64,
    // Surge intensity as a multiplier (e.g., 1.0 = no surge, 1.5 = 50% surge, 2.0 = 100% surge)
    pub intensity: f64,
}

/// Calculate surge heatmap grid using Kernel Density Estimation (KDE)
pub fn calculate_surge_heatmap(
    center_lat: f64,
    center_lng: f64,
    grid_size: i32,         // e.g. 10 means 10x10 grid
    cell_size_degrees: f64, // e.g. 0.003 degrees step size
    request_lats: Vec<f64>,
    request_lngs: Vec<f64>,
) -> Vec<HeatmapCell> {
    let mut cells = Vec::new();
    let half_grid = grid_size as f64 / 2.0;

    // KDE bandwidth parameter in kilometers (e.g., 0.8 km)
    let bandwidth: f64 = 0.8;

    for i in 0..grid_size {
        for j in 0..grid_size {
            // Offset coordinates around the center point
            let lat_offset = (i as f64 - half_grid) * cell_size_degrees;
            let lng_offset = (j as f64 - half_grid) * cell_size_degrees;
            let cell_lat = center_lat + lat_offset;
            let cell_lng = center_lng + lng_offset;

            // KDE Density Calculation
            let mut density_sum = 0.0;
            for (req_lat, req_lng) in request_lats.iter().zip(request_lngs.iter()) {
                let dist = haversine_distance(cell_lat, cell_lng, *req_lat, *req_lng);
                // Gaussian Kernel: K(u) = exp(-0.5 * u^2)
                let u = dist / bandwidth;
                density_sum += (-0.5 * u * u).exp();
            }

            // Calculate surge multiplier from density: base of 1.0 up to max 2.5
            let surge = 1.0 + (density_sum * 0.2).min(1.5);

            cells.push(HeatmapCell {
                lat: cell_lat,
                lng: cell_lng,
                intensity: (surge * 100.0).round() / 100.0,
            });
        }
    }

    cells
}

#[derive(Debug, Clone)]
pub struct Waypoint {
    pub id: String,
    pub name: String,
    pub lat: f64,
    pub lng: f64,
    pub is_pickup: bool,
    pub passenger_id: String,
}

#[derive(Debug, Clone)]
pub struct RouteSequenceResult {
    pub optimal_sequence: Vec<Waypoint>,
    pub total_distance_km: f64,
}

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
