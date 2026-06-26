use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;

pub mod domain;
pub mod models;
pub mod repository;
pub mod handlers;

use domain::PassengerRepository;

/**
 * Builds and returns the passenger feature module Router.
 * Configures REST endpoints and binds handlers to the repository state.
 */
pub fn router(repo: Arc<dyn PassengerRepository>) -> Router {
    Router::new()
        .route("/passengers", post(handlers::create_passenger))
        .route("/passengers/:id", get(handlers::get_passenger))
        .route("/rides", post(handlers::request_ride))
        .route("/passengers/:id/rides", get(handlers::get_passenger_rides))
        .with_state(repo)
}
