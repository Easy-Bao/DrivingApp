use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use std::sync::Arc;
use tracing::info;

use passenger_service::handlers;
use passenger_service::repository::{InMemoryPassengerRepository, PassengerRepository, PostgresPassengerRepository};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing subscriber for runtime diagnostics logging
    tracing_subscriber::fmt::init();

    info!("Passenger service starting...");

    // Dynamically resolve repository backend based on environmental context.
    // Enables seamless fallback to an In-Memory state store during development/testing.
    let repo: Arc<dyn PassengerRepository> = if let Ok(database_url) = std::env::var("DATABASE_URL") {
        info!("PostgreSQL database configuration detected. Connecting...");
        let pool = sqlx::PgPool::connect(&database_url).await?;
        let postgres_repo = PostgresPassengerRepository::new(pool);
        postgres_repo.init_db().await?;
        info!("PostgreSQL database tables successfully initialized.");
        Arc::new(postgres_repo)
    } else {
        info!("DATABASE_URL environment variable is missing. Falling back to InMemoryPassengerRepository.");
        Arc::new(InMemoryPassengerRepository::new())
    };

    // Construct the web service router mapping REST endpoints to logic handlers
    let app = Router::new()
        .route("/passengers", post(handlers::create_passenger))
        .route("/passengers/:id", get(handlers::get_passenger))
        .route("/rides", post(handlers::request_ride))
        .route("/passengers/:id/rides", get(handlers::get_passenger_rides))
        .with_state(repo);

    // Bind socket address and start server listener loop
    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "8081".to_string())
        .parse::<u16>()?;
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr).await?;
    
    info!("Passenger service is listening at: http://{}", addr);
    axum::serve(listener, app).await?;

    Ok(())
}
