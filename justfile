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

ci-guards:
    @./scripts/ci/quality_guard.sh

ci-backend-install:
    @./scripts/ci/install_backend_dependencies.sh

ci-backend-typecheck:
    @./scripts/ci/typecheck_backend_services.sh

ci-backend-test:
    @./scripts/ci/test_backend_services.sh

ci-backend: ci-backend-install ci-backend-typecheck ci-backend-test
    cd server/location-service && go vet ./...
    cd server/location-service && go test ./...

ci-flutter:
    flutter pub global run melos bootstrap
    dart format --set-exit-if-changed apps packages
    flutter pub global run melos run analyze
    cd apps/driver_app && flutter test
    cd apps/passenger_app && flutter test

ci-local: ci-guards ci-flutter ci-backend

bootstrap:
    flutter pub global run melos bootstrap

db-up:
    docker compose up -d postgres-db
    @echo "PostgreSQL started on port 5432"

db-down:
    docker compose stop postgres-db

# Start shared local infrastructure and wait for its health checks
infra-up:
    ADMIN_JWT_SECRET="$$(openssl rand -hex 32)" docker compose up -d --wait --wait-timeout 60 postgres-db redis rabbitmq

# Idempotently initialize databases and tables required by local authentication
db-migrate: infra-up
    @./scripts/database/apply_service_schemas.sh

test-services:
    @echo "=== Auth Service ==="
    cd server/auth-service && bun test
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
    @echo "=== Fare Service ==="
    cd server/fare-service && bun test
    @echo "=== Location Service ==="
    cd server/location-service && go test ./...

start-all: db-migrate
    @./scripts/start_all.sh

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
