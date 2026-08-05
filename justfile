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
    cd server && go generate ./ent/generate.go

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
    docker compose up -d --remove-orphans --wait --wait-timeout 60 postgres-db redis rabbitmq

# Idempotently apply the single Ent migration stream
db-migrate: infra-up
    @./scripts/database/migrate.sh

test-services:
    cd server && go test ./...

start-all: db-migrate
    @./scripts/start_all.sh

# Reverse ports for all connected Android devices/emulators
adb-reverse:
    @./scripts/adb_reverse.sh

# Start all docker compose containers in background
docker-up:
    docker compose up -d --remove-orphans

# Stop all compose containers
docker-down:
    docker compose down

# Build or rebuild compose images
docker-build:
    docker compose build

# View logs for compose containers
docker-logs:
    docker compose logs -f

generate-ent:
    cd server && go generate ./ent/generate.go
