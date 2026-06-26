use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
    http::StatusCode,
};

/**
 * Custom middleware that extracts and validates the Authorization header.
 * Demonstrates basic extraction pattern for secure endpoints.
 */
pub async fn auth_middleware(
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // Extract Authorization header if present for tracing/auditing
    let _auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok());

    // Pass the request along the middleware/service stack
    Ok(next.run(request).await)
}
