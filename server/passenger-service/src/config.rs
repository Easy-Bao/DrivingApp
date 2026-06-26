/**
 * Configuration registry parsed from environment variables.
 */
#[derive(Debug, Clone)]
pub struct Config {
    /** The database connection URI for PostgreSQL. */
    pub database_url: Option<String>,
    /** The port on which the microservice runs. Defaults to 8081. */
    pub port: u16,
}

impl Config {
    /** Parses and returns configuration from environmental variables. */
    pub fn from_env() -> Self {
        let database_url = std::env::var("DATABASE_URL").ok();
        let port = std::env::var("PORT")
            .ok()
            .and_then(|p| p.parse::<u16>().ok())
            .unwrap_or(8081);
        Self { database_url, port }
    }
}
