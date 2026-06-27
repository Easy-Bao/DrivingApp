# Multi-stage Docker build for the passenger-service Rust service.
FROM rust:1.78-bookworm AS builder

WORKDIR /app

COPY server/Cargo.toml server/Cargo.lock ./server/
COPY server/shared-core ./server/shared-core
COPY server/passenger-service ./server/passenger-service

WORKDIR /app/server/passenger-service

RUN cargo build --release

FROM debian:bookworm-slim

WORKDIR /app

COPY --from=builder /app/server/target/release/passenger-service /app/passenger-service

EXPOSE 8081

CMD ["/app/passenger-service"]
