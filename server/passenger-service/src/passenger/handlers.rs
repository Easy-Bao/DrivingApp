/// Passenger Handlers: defines Axum HTTP handler functions for managing passengers, login, and ride requests.
use super::domain::PassengerRepository;
use super::models::{CreatePassengerRequest, CreateRideRequest, LoginRequest, LoginResponse};
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use chrono::Utc;
use std::sync::Arc;
use uuid::Uuid;

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

pub async fn login(
    State(repo): State<Arc<dyn PassengerRepository>>,
    Json(payload): Json<LoginRequest>,
) -> impl IntoResponse {
    match repo.get_passenger_by_email(&payload.email).await {
        Ok(Some(passenger)) => match bcrypt::verify(&payload.password, &passenger.password_hash) {
            Ok(true) => {
                let jwt_secret =
                    std::env::var("JWT_SECRET").unwrap_or_else(|_| "secret".to_string());
                let expiration = match Utc::now().checked_add_signed(chrono::Duration::hours(24)) {
                    Some(exp) => exp.timestamp() as usize,
                    None => {
                        return (
                            StatusCode::INTERNAL_SERVER_ERROR,
                            Json(serde_json::json!({ "error": "Timestamp overflow" })),
                        )
                            .into_response();
                    }
                };

                #[derive(Debug, serde::Serialize, serde::Deserialize)]
                struct Claims {
                    sub: String,
                    exp: usize,
                }

                let claims = Claims {
                    sub: passenger.id.to_string(),
                    exp: expiration,
                };

                match jsonwebtoken::encode(
                    &jsonwebtoken::Header::default(),
                    &claims,
                    &jsonwebtoken::EncodingKey::from_secret(jwt_secret.as_bytes()),
                ) {
                    Ok(token) => {
                        (StatusCode::OK, Json(LoginResponse { token, passenger })).into_response()
                    }
                    Err(e) => (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(
                            serde_json::json!({ "error": format!("Token signing failed: {}", e) }),
                        ),
                    )
                        .into_response(),
                }
            }
            Ok(false) => (
                StatusCode::UNAUTHORIZED,
                Json(serde_json::json!({ "error": "Invalid email or password" })),
            )
                .into_response(),
            Err(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({ "error": e.to_string() })),
            )
                .into_response(),
        },
        Ok(None) => (
            StatusCode::UNAUTHORIZED,
            Json(serde_json::json!({ "error": "Invalid email or password" })),
        )
            .into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({ "error": e.to_string() })),
        )
            .into_response(),
    }
}

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
