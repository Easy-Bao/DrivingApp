use crate::models::fare_models::HeatmapCell;
use crate::shared::math::haversine_distance;

/// Calculate surge heatmap grid using Kernel Density Estimation (KDE)
pub fn calculate_surge_heatmap(
    center_lat: f64,
    center_lng: f64,
    grid_size: i32,
    cell_size_degrees: f64,
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
