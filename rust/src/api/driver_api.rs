use crate::models::driver_models::NearbyDriver;
use crate::services;

pub fn find_nearby_drivers(passenger_lat: f64, passenger_lng: f64) -> Vec<NearbyDriver> {
    services::driver_service::find_nearby_drivers(passenger_lat, passenger_lng)
}
