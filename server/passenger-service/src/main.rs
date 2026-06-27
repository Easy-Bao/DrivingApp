/// Application entry point: initializes logging, DB migrations, repositories, and axum HTTP server.
use std::net::SocketAddr;
use std::sync::Arc;
use tracing::info;

use passenger_service::config::Config;
use passenger_service::passenger::{
    domain::PassengerRepository,
    repository::{InMemoryPassengerRepository, PostgresPassengerRepository},
    router,
};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    info!("Passenger Server Starting");

    let config = Config::from_env();

    let repo: Arc<dyn PassengerRepository> = if let Some(ref database_url) = config.database_url {
        let pool = sqlx::PgPool::connect(database_url).await?;

        sqlx::migrate!("./migrations").run(&pool).await?;
        info!("Database Migrations Applied Successfully.");

        Arc::new(PostgresPassengerRepository::new(pool)) as Arc<dyn PassengerRepository>
    } else {
        info!("DATABASE_URL environment variable is missing. Falling back to InMemoryPassengerRepository.");
        Arc::new(InMemoryPassengerRepository::new()) as Arc<dyn PassengerRepository>
    };

    let app = router(repo);

    let addr = SocketAddr::from(([0, 0, 0, 0], config.port));
    let listener = tokio::net::TcpListener::bind(addr).await?;

    info!("Passenger service is listening at: http://{}", addr);
    axum::serve(listener, app).await?;

    Ok(())
}
