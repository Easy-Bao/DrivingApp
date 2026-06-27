# Multi-stage Docker build for the passenger-service Rust service.
FROM rust:latest AS builder

WORKDIR /app

COPY server/ ./server/

WORKDIR /app/server/passenger-service

RUN cargo build --release

FROM debian:bookworm-slim

WORKDIR /app

COPY --from=builder /app/server/target/release/passenger-service /app/passenger-service

EXPOSE 8081

CMD ["/app/passenger-service"]
