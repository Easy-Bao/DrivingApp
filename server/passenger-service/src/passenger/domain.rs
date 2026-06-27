/// Passenger Domain: defines core domain models, ride types, and repository interfaces.
use anyhow::Result;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;
use uuid::Uuid;

use super::models::{CreatePassengerRequest, CreateRideRequest};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RideType {
    SoloRide,
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
        match s.to_lowercase().replace(['_', ' '], "-").as_str() {
            "solo-ride" | "soloride" | "solo" => Ok(RideType::SoloRide),
            "share-bao" | "sharebao" => Ok(RideType::ShareBao),
            _ => Err(anyhow::anyhow!("Unsupported ride type: '{}'", s)),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Passenger {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub phone: String,
    pub preferred_ride_type: Option<RideType>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RideRequest {
    pub id: Uuid,
    pub passenger_id: Uuid,
    pub ride_type: RideType,
    pub pickup_latitude: f64,
    pub pickup_longitude: f64,
    pub pickup_name: String,
    pub dropoff_latitude: f64,
    pub dropoff_longitude: f64,
    pub dropoff_name: String,
    pub fare: f64,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

#[async_trait::async_trait]
pub trait PassengerRepository: Send + Sync {
    async fn create_passenger(&self, req: CreatePassengerRequest) -> Result<Passenger>;
    async fn get_passenger(&self, id: Uuid) -> Result<Option<Passenger>>;
    async fn create_ride_request(&self, req: CreateRideRequest) -> Result<RideRequest>;
    async fn get_passenger_rides(&self, passenger_id: Uuid) -> Result<Vec<RideRequest>>;
}
