use crate::models::fare_models::{FareConfig, FareResult};

/// Compute the fare for a ride given distance, duration, and pricing config.
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
