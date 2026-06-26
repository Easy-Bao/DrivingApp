use serde::{Deserialize, Serialize};
use uuid::Uuid;

/**
 * Input request payload used when registering a new passenger profile.
 */
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreatePassengerRequest {
    /** Full name of the passenger. */
    pub name: String,
    /** Email address of the passenger. */
    pub email: String,
    /** Mobile phone number of the passenger. */
    pub phone: String,
    /** Optional default ride booking preference. */
    pub preferred_ride_type: Option<String>,
}

/**
 * Input request payload used when submitting a new ride request.
 */
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CreateRideRequest {
    /** Unique identifier of the passenger booking the ride. */
    pub passenger_id: Uuid,
    /** Selected ride type (e.g. 'solo-ride' or 'share-bao'). */
    pub ride_type: String,
    /** Origin coordinate latitude. */
    pub pickup_latitude: f64,
    /** Origin coordinate longitude. */
    pub pickup_longitude: f64,
    /** Origin text location name. */
    pub pickup_name: String,
    /** Destination coordinate latitude. */
    pub dropoff_latitude: f64,
    /** Destination coordinate longitude. */
    pub dropoff_longitude: f64,
    /** Destination text location name. */
    pub dropoff_name: String,
    /** Negotiated or base fare for this trip request. */
    pub fare: f64,
}
