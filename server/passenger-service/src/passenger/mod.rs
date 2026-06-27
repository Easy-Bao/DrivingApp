/// Passenger module entry: defines sub-modules and exports the feature router for API endpoints.
use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;

pub mod domain;
pub mod handlers;
pub mod models;
pub mod repository;

use domain::PassengerRepository;

pub fn router(repo: Arc<dyn PassengerRepository>) -> Router {
    Router::new()
        .route("/passengers", post(handlers::create_passenger))
        .route("/passengers/:id", get(handlers::get_passenger))
        .route("/rides", post(handlers::request_ride))
        .route("/passengers/:id/rides", get(handlers::get_passenger_rides))
        .with_state(repo)
}
