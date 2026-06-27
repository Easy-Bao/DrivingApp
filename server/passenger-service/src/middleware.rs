/// HTTP Middleware: extracts the Authorization header and passes requests along the stack.
use axum::{
    extract::Request,
    http::StatusCode,
    middleware::Next,
    response::Response,
};

pub async fn auth_middleware(
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let _auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok());

    Ok(next.run(request).await)
}
