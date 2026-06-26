use crate::models::{CreatePassengerRequest, CreateRideRequest, Passenger, RideRequest, RideType};
use anyhow::{anyhow, Result};
use chrono::Utc;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

/// Contract defining database access operations for managing passenger data.
/// Promotes clean separation of concerns and database independence for test mocking.
#[async_trait::async_trait]
pub trait PassengerRepository: Send + Sync {
    /// Registers a new passenger profile.
    async fn create_passenger(&self, req: CreatePassengerRequest) -> Result<Passenger>;
    
    /// Retrieves a passenger profile by its unique ID.
    async fn get_passenger(&self, id: Uuid) -> Result<Option<Passenger>>;
    
    /// Creates a new ride request under a specific passenger profile.
    async fn create_ride_request(&self, req: CreateRideRequest) -> Result<RideRequest>;
    
    /// Returns all ride requests initiated by a specific passenger.
    async fn get_passenger_rides(&self, passenger_id: Uuid) -> Result<Vec<RideRequest>>;
}

/// An in-memory, thread-safe implementation of [PassengerRepository].
/// Useful for unit testing, integration tests, and local offline development.
#[derive(Debug, Default, Clone)]
pub struct InMemoryPassengerRepository {
    passengers: Arc<RwLock<HashMap<Uuid, Passenger>>>,
    rides: Arc<RwLock<HashMap<Uuid, Vec<RideRequest>>>>,
}

impl InMemoryPassengerRepository {
    /// Creates a new empty database instance in system memory.
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
        let preferred_ride_type = match req.preferred_ride_type {
            Some(ref t) => Some(RideType::from_str(t)?),
            None => None,
        };

        let mut passengers_guard = self.passengers.write().await;
        
        // Prevent duplicate emails
        if passengers_guard.values().any(|p| p.email == req.email) {
            return Err(anyhow!("A passenger with email {} already exists", req.email));
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
        
        // Verify passenger exists
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
        // Verify passenger exists
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

/// Postgres-backed implementation of [PassengerRepository] utilizing SQLx.
#[derive(Debug, Clone)]
pub struct PostgresPassengerRepository {
    pool: sqlx::PgPool,
}

impl PostgresPassengerRepository {
    /// Creates a new Postgres database adapter.
    pub fn new(pool: sqlx::PgPool) -> Self {
        Self { pool }
    }

    /// Pre-run initialization that establishes the database tables if they do not exist.
    pub async fn init_db(&self) -> Result<()> {
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS passengers (
                id UUID PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL UNIQUE,
                phone VARCHAR(50) NOT NULL,
                preferred_ride_type VARCHAR(50),
                created_at TIMESTAMPTZ NOT NULL
            );
            "#
        )
        .execute(&self.pool)
        .await?;

        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS ride_requests (
                id UUID PRIMARY KEY,
                passenger_id UUID NOT NULL REFERENCES passengers(id),
                ride_type VARCHAR(50) NOT NULL,
                pickup_latitude DOUBLE PRECISION NOT NULL,
                pickup_longitude DOUBLE PRECISION NOT NULL,
                pickup_name VARCHAR(255) NOT NULL,
                dropoff_latitude DOUBLE PRECISION NOT NULL,
                dropoff_longitude DOUBLE PRECISION NOT NULL,
                dropoff_name VARCHAR(255) NOT NULL,
                fare DOUBLE PRECISION NOT NULL,
                status VARCHAR(50) NOT NULL,
                created_at TIMESTAMPTZ NOT NULL
            );
            "#
        )
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}

#[async_trait::async_trait]
impl PassengerRepository for PostgresPassengerRepository {
    async fn create_passenger(&self, req: CreatePassengerRequest) -> Result<Passenger> {
        let preferred_ride_type = match req.preferred_ride_type {
            Some(ref t) => Some(RideType::from_str(t)?),
            None => None,
        };

        let id = Uuid::new_v4();
        let created_at = Utc::now();
        let pref_str = preferred_ride_type.map(|t| t.to_string());

        sqlx::query(
            r#"
            INSERT INTO passengers (id, name, email, phone, preferred_ride_type, created_at)
            VALUES ($1, $2, $3, $4, $5, $6)
            "#
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
            "#
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        match row {
            Some(r) => {
                let preferred_ride_type_str: Option<String> = r.try_get("preferred_ride_type")?;
                let preferred_ride_type = match preferred_ride_type_str.as_deref() {
                    Some(t) => Some(RideType::from_str(t)?),
                    None => None,
                };
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
            "#
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

        // Verify passenger exists
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
            "#
        )
        .bind(passenger_id)
        .fetch_all(&self.pool)
        .await?;

        let mut rides = Vec::new();
        for r in rows {
            let ride_type_str: String = r.try_get("ride_type")?;
            rides.push(RideRequest {
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
            });
        }

        Ok(rides)
    }
}
