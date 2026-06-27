/// Passenger Repository: persistence backend implementing SQLx postgres operations and thread-safe in-memory caching.
use anyhow::{anyhow, Result};
use chrono::Utc;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

use super::domain::{Passenger, PassengerRepository, RideRequest, RideType};
use super::models::{CreatePassengerRequest, CreateRideRequest};

#[derive(Debug, Default, Clone)]
pub struct InMemoryPassengerRepository {
    passengers: Arc<RwLock<HashMap<Uuid, Passenger>>>,
    rides: Arc<RwLock<HashMap<Uuid, Vec<RideRequest>>>>,
}

impl InMemoryPassengerRepository {
    pub fn new() -> Self {
        Self {
            passengers: Arc::new(RwLock::new(HashMap::new())),
            rides: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}

#[async_trait::async_trait]
impl PassengerRepository for InMemoryPassengerRepository {
    async fn create_passenger(&self, req: CreatePassengerRequest) -> Result<Passenger> {
        let preferred_ride_type = req
            .preferred_ride_type
            .as_deref()
            .map(RideType::from_str)
            .transpose()?;

        let mut passengers_guard = self.passengers.write().await;

        if passengers_guard.values().any(|p| p.email == req.email) {
            return Err(anyhow!(
                "A passenger with email {} already exists",
                req.email
            ));
        }

        let passenger = Passenger {
            id: Uuid::new_v4(),
            name: req.name,
            email: req.email,
            phone: req.phone,
            preferred_ride_type,
            created_at: Utc::now(),
        };

        passengers_guard.insert(passenger.id, passenger.clone());
        Ok(passenger)
    }

    async fn get_passenger(&self, id: Uuid) -> Result<Option<Passenger>> {
        let passengers_guard = self.passengers.read().await;
        Ok(passengers_guard.get(&id).cloned())
    }

    async fn create_ride_request(&self, req: CreateRideRequest) -> Result<RideRequest> {
        let ride_type = RideType::from_str(&req.ride_type)?;

        {
            let passengers_guard = self.passengers.read().await;
            if !passengers_guard.contains_key(&req.passenger_id) {
                return Err(anyhow!("Passenger ID {} not found", req.passenger_id));
            }
        }

        let ride = RideRequest {
            id: Uuid::new_v4(),
            passenger_id: req.passenger_id,
            ride_type,
            pickup_latitude: req.pickup_latitude,
            pickup_longitude: req.pickup_longitude,
            pickup_name: req.pickup_name,
            dropoff_latitude: req.dropoff_latitude,
            dropoff_longitude: req.dropoff_longitude,
            dropoff_name: req.dropoff_name,
            fare: req.fare,
            status: "requested".to_string(),
            created_at: Utc::now(),
        };

        let mut rides_guard = self.rides.write().await;
        rides_guard
            .entry(req.passenger_id)
            .or_default()
            .push(ride.clone());

        Ok(ride)
    }

    async fn get_passenger_rides(&self, passenger_id: Uuid) -> Result<Vec<RideRequest>> {
        {
            let passengers_guard = self.passengers.read().await;
            if !passengers_guard.contains_key(&passenger_id) {
                return Err(anyhow!("Passenger ID {} not found", passenger_id));
            }
        }

        let rides_guard = self.rides.read().await;
        Ok(rides_guard.get(&passenger_id).cloned().unwrap_or_default())
    }
}

#[derive(Debug, Clone)]
pub struct PostgresPassengerRepository {
    pool: sqlx::PgPool,
}

impl PostgresPassengerRepository {
    pub fn new(pool: sqlx::PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait::async_trait]
impl PassengerRepository for PostgresPassengerRepository {
    async fn create_passenger(&self, req: CreatePassengerRequest) -> Result<Passenger> {
        let preferred_ride_type = req
            .preferred_ride_type
            .as_deref()
            .map(RideType::from_str)
            .transpose()?;

        let id = Uuid::new_v4();
        let created_at = Utc::now();
        let pref_str = preferred_ride_type.map(|t| t.to_string());

        sqlx::query(
            r#"
            INSERT INTO passengers (id, name, email, phone, preferred_ride_type, created_at)
            VALUES ($1, $2, $3, $4, $5, $6)
            "#,
        )
        .bind(id)
        .bind(&req.name)
        .bind(&req.email)
        .bind(&req.phone)
        .bind(pref_str)
        .bind(created_at)
        .execute(&self.pool)
        .await?;

        Ok(Passenger {
            id,
            name: req.name,
            email: req.email,
            phone: req.phone,
            preferred_ride_type,
            created_at,
        })
    }

    async fn get_passenger(&self, id: Uuid) -> Result<Option<Passenger>> {
        use sqlx::Row;
        let row = sqlx::query(
            r#"
            SELECT name, email, phone, preferred_ride_type, created_at
            FROM passengers
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        match row {
            Some(r) => {
                let preferred_ride_type_str: Option<String> = r.try_get("preferred_ride_type")?;
                let preferred_ride_type = preferred_ride_type_str
                    .as_deref()
                    .map(RideType::from_str)
                    .transpose()?;
                Ok(Some(Passenger {
                    id,
                    name: r.try_get("name")?,
                    email: r.try_get("email")?,
                    phone: r.try_get("phone")?,
                    preferred_ride_type,
                    created_at: r.try_get("created_at")?,
                }))
            }
            None => Ok(None),
        }
    }

    async fn create_ride_request(&self, req: CreateRideRequest) -> Result<RideRequest> {
        let ride_type = RideType::from_str(&req.ride_type)?;
        let id = Uuid::new_v4();
        let created_at = Utc::now();
        let status = "requested".to_string();

        sqlx::query(
            r#"
            INSERT INTO ride_requests (
                id, passenger_id, ride_type, pickup_latitude, pickup_longitude, pickup_name,
                dropoff_latitude, dropoff_longitude, dropoff_name, fare, status, created_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            "#,
        )
        .bind(id)
        .bind(req.passenger_id)
        .bind(ride_type.to_string())
        .bind(req.pickup_latitude)
        .bind(req.pickup_longitude)
        .bind(&req.pickup_name)
        .bind(req.dropoff_latitude)
        .bind(req.dropoff_longitude)
        .bind(&req.dropoff_name)
        .bind(req.fare)
        .bind(&status)
        .bind(created_at)
        .execute(&self.pool)
        .await?;

        Ok(RideRequest {
            id,
            passenger_id: req.passenger_id,
            ride_type,
            pickup_latitude: req.pickup_latitude,
            pickup_longitude: req.pickup_longitude,
            pickup_name: req.pickup_name,
            dropoff_latitude: req.dropoff_latitude,
            dropoff_longitude: req.dropoff_longitude,
            dropoff_name: req.dropoff_name,
            fare: req.fare,
            status,
            created_at,
        })
    }

    async fn get_passenger_rides(&self, passenger_id: Uuid) -> Result<Vec<RideRequest>> {
        use sqlx::Row;

        let exists_row = sqlx::query("SELECT EXISTS(SELECT 1 FROM passengers WHERE id = $1)")
            .bind(passenger_id)
            .fetch_one(&self.pool)
            .await?;
        let exists: bool = exists_row.try_get(0)?;

        if !exists {
            return Err(anyhow!("Passenger ID {} not found", passenger_id));
        }

        let rows = sqlx::query(
            r#"
            SELECT id, ride_type, pickup_latitude, pickup_longitude, pickup_name,
                   dropoff_latitude, dropoff_longitude, dropoff_name, fare, status, created_at
            FROM ride_requests
            WHERE passenger_id = $1
            ORDER BY created_at DESC
            "#,
        )
        .bind(passenger_id)
        .fetch_all(&self.pool)
        .await?;

        rows.into_iter()
            .map(|r| {
                let ride_type_str: String = r.try_get("ride_type")?;
                Ok(RideRequest {
                    id: r.try_get("id")?,
                    passenger_id,
                    ride_type: RideType::from_str(&ride_type_str)?,
                    pickup_latitude: r.try_get("pickup_latitude")?,
                    pickup_longitude: r.try_get("pickup_longitude")?,
                    pickup_name: r.try_get("pickup_name")?,
                    dropoff_latitude: r.try_get("dropoff_latitude")?,
                    dropoff_longitude: r.try_get("dropoff_longitude")?,
                    dropoff_name: r.try_get("dropoff_name")?,
                    fare: r.try_get("fare")?,
                    status: r.try_get("status")?,
                    created_at: r.try_get("created_at")?,
                })
            })
            .collect::<Result<Vec<_>>>()
    }
}
