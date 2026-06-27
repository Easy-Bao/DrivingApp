/**
 * Configuration registry parsed from environment variables.
 */
#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: Option<String>,
    pub port: u16,
}

impl Config {
    pub fn from_env() -> Self {
        let database_url = std::env::var("DATABASE_URL").ok();
        let port = std::env::var("PORT")
            .ok()
            .and_then(|p| p.parse::<u16>().ok())
            .unwrap_or(8081);
        Self { database_url, port }
    }
}
