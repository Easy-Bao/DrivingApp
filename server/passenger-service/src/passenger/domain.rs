use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;
use uuid::Uuid;
use anyhow::Result;

use super::models::{CreatePassengerRequest, CreateRideRequest};

/**
 * Represents the classification of a booking request or passenger preference.
 * Supports both 'solo-ride' and 'share-bao' options.
 */
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RideType {
    /** Direct booking options for a single passenger. */
    SoloRide,
    /** Shared booking options for split-fare ride sharing. */
    ShareBao,
}

impl fmt::Display for RideType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RideType::SoloRide => write!(f, "solo-ride"),
            RideType::ShareBao => write!(f, "share-bao"),
        }
    }
}

impl FromStr for RideType {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().replace('_', "-").replace(' ', "-").as_str() {
            "solo-ride" | "soloride" | "solo" => Ok(RideType::SoloRide),
            "share-bao" | "sharebao" => Ok(RideType::ShareBao),
            _ => Err(anyhow::anyhow!("Unsupported ride type: '{}'", s)),
        }
    }
}

/**
 * Profile account model representing registered passengers within the database.
 */
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Passenger {
    /** Unique identifier for the passenger account. */
    pub id: Uuid,
    /** Full name of the passenger. */
    pub name: String,
    /** Primary email address used for receipts and authentication. */
    pub email: String,
    /** Verified phone number used for contact and verification. */
    pub phone: String,
    /** Optional preferred ride option saved as a default profile setting. */
    pub preferred_ride_type: Option<RideType>,
    /** Creation timestamp representing when the account was registered. */
    pub created_at: DateTime<Utc>,
}

/**
 * Lifecycle tracking state for an active passenger ride request.
 */
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RideRequest {
    /** Unique identifier representing the ride request. */
    pub id: Uuid,
    /** Unique identifier of the passenger who initiated the request. */
    pub passenger_id: Uuid,
    /** The ride category selection. */
    pub ride_type: RideType,
    /** Latitude coordinates representing the origin pickup point. */
    pub pickup_latitude: f64,
    /** Longitude coordinates representing the origin pickup point. */
    pub pickup_longitude: f64,
    /** Text address descriptor for the pickup origin point. */
    pub pickup_name: String,
    /** Latitude coordinates representing the target destination drop-off point. */
    pub dropoff_latitude: f64,
    /** Longitude coordinates representing the target destination drop-off point. */
    pub dropoff_longitude: f64,
    /** Text address descriptor for the destination drop-off point. */
    pub dropoff_name: String,
    /** Calculated fare cost of the booking in Philippine Peso (PHP). */
    pub fare: f64,
    /** Operational status of the request ('requested', 'accepted', 'completed', 'cancelled'). */
    pub status: String,
    /** Timestamp representing when the ride request was logged. */
    pub created_at: DateTime<Utc>,
}

/**
 * Contract defining database access operations for managing passenger data.
 * Promotes clean separation of concerns and database independence for test mocking.
 */
#[async_trait::async_trait]
pub trait PassengerRepository: Send + Sync {
    /** Registers a new passenger profile. */
    async fn create_passenger(&self, req: CreatePassengerRequest) -> Result<Passenger>;
    
    /** Retrieves a passenger profile by its unique ID. */
    async fn get_passenger(&self, id: Uuid) -> Result<Option<Passenger>>;
    
    /** Creates a new ride request under a specific passenger profile. */
    async fn create_ride_request(&self, req: CreateRideRequest) -> Result<RideRequest>;
    
    /** Returns all ride requests initiated by a specific passenger. */
    async fn get_passenger_rides(&self, passenger_id: Uuid) -> Result<Vec<RideRequest>>;
}
