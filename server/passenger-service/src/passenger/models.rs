/// Passenger Models: defines input payloads for creating passenger profiles, login, and ride requests.
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreatePassengerRequest {
    pub name: String,
    pub email: String,
    pub phone: String,
    pub password: String,
    pub preferred_ride_type: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoginResponse {
    pub token: String,
    pub passenger: super::domain::Passenger,
}

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
