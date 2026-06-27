use serde::{Deserialize, Serialize};
use uuid::Uuid;

/**
 * Input request payload used when registering a new passenger profile.
 */
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreatePassengerRequest {
    pub name: String,
    pub email: String,
    pub phone: String,
    pub preferred_ride_type: Option<String>,
}

/**
 * Input request payload used when submitting a new ride request.
 */
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreateRideRequest {
    pub passenger_id: Uuid,
    pub ride_type: String,
    pub pickup_latitude: f64,
    pub pickup_longitude: f64,
    pub pickup_name: String,
    pub dropoff_latitude: f64,
    pub dropoff_longitude: f64,
    pub dropoff_name: String,
    pub fare: f64,
}
