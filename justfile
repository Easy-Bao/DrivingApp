# Justfile configuring development, build, test, and container recipes.
default:
    @just --list

clean:
    flutter clean
    flutter pub get

update:
    flutter pub upgrade

watch-flutter:
    dart run build_runner watch --delete-conflicting-outputs

analyze:
    flutter pub global run melos run analyze

bootstrap:
    flutter pub global run melos bootstrap

db-up:
    docker compose up -d passenger-db
    @echo "PostgreSQL started on port 5432"

db-down:
    docker compose stop passenger-db

db-migrate:
    docker exec driveapp-passenger-db-1 psql -U driveapp -d passenger_db -f /dev/stdin < server/passenger-service/prisma/migrations/20260626000000_create_passenger_tables/migration.sql
    docker exec driveapp-passenger-db-1 psql -U driveapp -d passenger_db -f /dev/stdin < server/passenger-service/prisma/migrations/20260627000000_add_password_hash/migration.sql

test-services:
    @echo "=== Passenger Service ==="
    cd server/passenger-service && bun test
    @echo "=== Driver Service ==="
    cd server/driver-service && bun test
    @echo "=== Trip Service ==="
    cd server/trip-service && bun test
    @echo "=== Telemetry Service ==="
    cd server/telemetry-service && bun test

[parallel]
start-all:
    cd server/api-gateway && bun run dev
    cd server/passenger-service && bun run dev
    cd server/driver-service && bun run dev
    cd server/trip-service && bun run dev
    cd server/bidding-service && bun run dev
    cd server/telemetry-service && bun run dev

run-passenger:
    cd apps/passenger_app && flutter run

run-driver:
    cd apps/driver_app && flutter run
