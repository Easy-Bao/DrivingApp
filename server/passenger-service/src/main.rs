use std::net::SocketAddr;
use std::sync::Arc;
use tracing::info;

use passenger_service::config::Config;
use passenger_service::passenger::{
    repository::{InMemoryPassengerRepository, PostgresPassengerRepository},
    domain::PassengerRepository,
    router,
};

/**
 * Service bootstrap entrypoint initializing environment config, tracing, database
 * pooling adapters, routing layers, and initiating the primary TCP server event loop.
 */
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing subscriber for runtime diagnostics logging
    tracing_subscriber::fmt::init();

    info!("Passenger service starting...");

    // Parse configuration from environment variables
    let config = Config::from_env();

    /*
     * Dynamically resolve repository backend based on environmental context.
     * Enables seamless fallback to an In-Memory state store during development/testing.
     */
    let repo: Arc<dyn PassengerRepository> = if let Some(ref database_url) = config.database_url {
        info!("PostgreSQL database configuration detected. Connecting...");
        let pool = sqlx::PgPool::connect(database_url).await?;
        let postgres_repo = PostgresPassengerRepository::new(pool);
        postgres_repo.init_db().await?;
        info!("PostgreSQL database tables successfully initialized.");
        Arc::new(postgres_repo)
    } else {
        info!("DATABASE_URL environment variable is missing. Falling back to InMemoryPassengerRepository.");
        Arc::new(InMemoryPassengerRepository::new())
    };

    // Construct the web service router mapping REST endpoints to logic handlers
    let app = router(repo);

    // Bind socket address and start server listener loop
    let addr = SocketAddr::from(([0, 0, 0, 0], config.port));
    let listener = tokio::net::TcpListener::bind(addr).await?;
    
    info!("Passenger service is listening at: http://{}", addr);
    axum::serve(listener, app).await?;

    Ok(())
}
