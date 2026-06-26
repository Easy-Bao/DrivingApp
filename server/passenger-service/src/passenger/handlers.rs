use super::domain::PassengerRepository;
use super::models::{CreatePassengerRequest, CreateRideRequest};
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

/**
 * Registers a new passenger profile.
 * Matches POST /passengers
 */
pub async fn create_passenger(
    State(repo): State<Arc<dyn PassengerRepository>>,
    Json(payload): Json<CreatePassengerRequest>,
) -> impl IntoResponse {
    match repo.create_passenger(payload).await {
        Ok(passenger) => (StatusCode::CREATED, Json(passenger)).into_response(),
        Err(e) => (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({ "error": e.to_string() })),
        )
            .into_response(),
    }
}

/**
 * Retrieves the profile details of an existing passenger.
 * Matches GET /passengers/:id
 */
pub async fn get_passenger(
    State(repo): State<Arc<dyn PassengerRepository>>,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    match repo.get_passenger(id).await {
        Ok(Some(passenger)) => (StatusCode::OK, Json(passenger)).into_response(),
        Ok(None) => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({ "error": format!("Passenger not found: {}", id) })),
        )
            .into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({ "error": e.to_string() })),
        )
            .into_response(),
    }
}

/**
 * Creates a new ride request (validates and registers solo-ride or share-bao bookings).
 * Matches POST /rides
 */
pub async fn request_ride(
    State(repo): State<Arc<dyn PassengerRepository>>,
    Json(payload): Json<CreateRideRequest>,
) -> impl IntoResponse {
    match repo.create_ride_request(payload).await {
        Ok(ride) => (StatusCode::CREATED, Json(ride)).into_response(),
        Err(e) => (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({ "error": e.to_string() })),
        )
            .into_response(),
    }
}

/**
 * Retrieves the historical ride requests initiated by a specific passenger.
 * Matches GET /passengers/:id/rides
 */
pub async fn get_passenger_rides(
    State(repo): State<Arc<dyn PassengerRepository>>,
    Path(passenger_id): Path<Uuid>,
) -> impl IntoResponse {
    match repo.get_passenger_rides(passenger_id).await {
        Ok(rides) => (StatusCode::OK, Json(rides)).into_response(),
        Err(e) => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({ "error": e.to_string() })),
        )
            .into_response(),
    }
}
