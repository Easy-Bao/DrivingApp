/// HTTP Middleware: extracts the Authorization header, validates the JWT, and passes requests along the stack.
use axum::{extract::Request, http::StatusCode, middleware::Next, response::Response};

pub async fn auth_middleware(request: Request, next: Next) -> Result<Response, StatusCode> {
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok());

    let token = match auth_header {
        Some(header) if header.starts_with("Bearer ") => &header[7..],
        _ => return Err(StatusCode::UNAUTHORIZED),
    };

    let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "secret".to_string());

    #[derive(Debug, serde::Deserialize)]
    struct Claims {
        sub: String,
        exp: usize,
    }

    let validation = jsonwebtoken::Validation::default();

    match jsonwebtoken::decode::<Claims>(
        token,
        &jsonwebtoken::DecodingKey::from_secret(jwt_secret.as_bytes()),
        &validation,
    ) {
        Ok(token_data) => {
            let passenger_id = token_data.claims.sub;
            let _exp = token_data.claims.exp;

            tracing::info!(
                "Authenticated passenger ID {} (expires at {})",
                passenger_id,
                _exp
            );

            let mut req = request;
            req.extensions_mut().insert(passenger_id);

            Ok(next.run(req).await)
        }
        Err(_) => Err(StatusCode::UNAUTHORIZED),
    }
}
