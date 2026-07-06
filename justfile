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
    @echo "=== Chat Service ==="
    cd server/chat-service && bun test

start-all:
    (cd server/api-gateway && bun run dev) & \
    (cd server/passenger-service && bun run dev) & \
    (cd server/driver-service && bun run dev) & \
    (cd server/trip-service && bun run dev) & \
    (cd server/bidding-service && bun run dev) & \
    (cd server/telemetry-service && bun run dev) & \
    (cd server/chat-service && bun run dev) & \
    wait

run-passenger:
    cd apps/passenger_app && flutter run

run-driver:
    cd apps/driver_app && flutter run

# Reverse ports for all connected Android devices/emulators
adb-reverse:
    @./scripts/adb_reverse.sh

# Start all docker compose containers in background
docker-up:
    docker compose up -d

# Stop all compose containers
docker-down:
    docker compose down

# Build or rebuild compose images
docker-build:
    docker compose build

# View logs for compose containers
docker-logs:
    docker compose logs -f

# Run prisma generate for all server services
prisma-generate:
    cd server/bidding-service && bunx prisma generate
    cd server/chat-service && bunx prisma generate
    cd server/driver-service && bunx prisma generate
    cd server/passenger-service && bunx prisma generate
    cd server/trip-service && bunx prisma generate

# Run prisma db push to apply schema changes directly
prisma-push:
    cd server/bidding-service && bunx prisma db push
    cd server/chat-service && bunx prisma db push
    cd server/driver-service && bunx prisma db push
    cd server/passenger-service && bunx prisma db push
    cd server/trip-service && bunx prisma db push

# Create or deploy prisma migrations
prisma-migrate name:
    cd server/bidding-service && bunx prisma migrate dev --name {{name}}
    cd server/chat-service && bunx prisma migrate dev --name {{name}}
    cd server/driver-service && bunx prisma migrate dev --name {{name}}
    cd server/passenger-service && bunx prisma migrate dev --name {{name}}
    cd server/trip-service && bunx prisma migrate dev --name {{name}}

# Deploy existing prisma migrations in production
prisma-deploy:
    cd server/bidding-service && bunx prisma migrate deploy
    cd server/chat-service && bunx prisma migrate deploy
    cd server/driver-service && bunx prisma migrate deploy
    cd server/passenger-service && bunx prisma migrate deploy
    cd server/trip-service && bunx prisma migrate deploy
