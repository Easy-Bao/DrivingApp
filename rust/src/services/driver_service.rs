use crate::models::driver_models::NearbyDriver;
use crate::shared::math::haversine_distance;

/// Discovers and ranks 5 nearby drivers relative to the passenger's current coordinates.
///
/// Implements a spatial proximity algorithm generating realistic drivers around the passenger's
/// location, then ranks them using a composite scoring algorithm balancing distance, rating, and ETA.
///
/// This design encapsulates all matching calculations in Rust for high-performance and accuracy,
/// while providing a clean boundary that can be easily replaced by a database/API query in the future.
pub fn find_nearby_drivers(passenger_lat: f64, passenger_lng: f64) -> Vec<NearbyDriver> {
    // Standard mock driver profiles
    let driver_pool = vec![
        (
            "drv_01",
            "Melvin Perez",
            "Habal-Habal Motorcycle",
            "987-PHP",
            4.9,
        ),
        (
            "drv_02",
            "Jerry Maglasang",
            "Premium BaoBao Trike",
            "321-XYZ",
            4.7,
        ),
        ("drv_03", "Ramil Sombilon", "Standard Trike", "555-ABC", 4.5),
        (
            "drv_04",
            "Crisanto Caboverde",
            "Habal-Habal Motorcycle",
            "888-BAO",
            4.8,
        ),
        (
            "drv_05",
            "Junrey Tugahan",
            "Premium BaoBao Trike",
            "777-RIDE",
            4.6,
        ),
    ];

    let mut drivers = Vec::new();

    // Distribute simulated drivers in different directions (N, NE, E, SE, S) around user
    // with offsets between 0.5km and 2.5km (1 degree lat ~ 111km)
    let angle_steps: [f64; 5] = [0.0, 45.0, 90.0, 135.0, 180.0];
    let distance_steps: [f64; 5] = [0.6, 1.2, 0.8, 2.1, 1.5]; // km

    for (idx, (id, name, vehicle_type, plate, rating)) in driver_pool.into_iter().enumerate() {
        let dist_km = distance_steps[idx];
        let angle_rad = angle_steps[idx].to_radians();

        // Approximate spatial displacement
        let lat_offset = (dist_km / 111.0) * angle_rad.cos();
        let lng_offset = (dist_km / (111.0 * passenger_lat.to_radians().cos())) * angle_rad.sin();

        let d_lat = passenger_lat + lat_offset;
        let d_lng = passenger_lng + lng_offset;

        // Calculate actual haversine distance to double check accuracy
        let actual_dist = haversine_distance(passenger_lat, passenger_lng, d_lat, d_lng);

        // Estimate ETA assuming average speed of 20 km/h in local traffic
        let eta_minutes = (actual_dist / 20.0 * 60.0).max(1.0);

        // Calculate composite score (lower is better)
        // 50% weight to distance, 30% weight to rating, 20% weight to ETA
        let score = (0.5 * actual_dist) + (0.3 * (5.0 - rating)) + (0.2 * eta_minutes);

        drivers.push(NearbyDriver {
            id: id.to_string(),
            name: name.to_string(),
            vehicle_type: vehicle_type.to_string(),
            plate_number: plate.to_string(),
            rating,
            lat: d_lat,
            lng: d_lng,
            distance_km: actual_dist,
            eta_minutes,
            score,
        });
    }

    // Sort by composite score (best/closest first)
    drivers.sort_by(|a, b| {
        a.score
            .partial_cmp(&b.score)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    drivers
}
