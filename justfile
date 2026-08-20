# Justfile configuring native development, build, test, and Docker recipes.

set dotenv-load
set export

api-base-url := env_var_or_default("API_BASE_URL", "http://127.0.0.1:8000")
api-port := env_var_or_default("API_PORT", env_var_or_default("GATEWAY_PORT", "8000"))

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
    dart run melos exec -- "flutter analyze --no-fatal-infos ."

ci-guards:
    git diff --check

ci-backend:
    cd server && go mod download
    cd server && go generate ./ent/generate.go
    cd server && go vet ./...
    cd server && go test ./...

ci-flutter:
    flutter pub get
    dart run melos bootstrap
    dart format --set-exit-if-changed apps packages
    dart run melos exec -- "flutter analyze --no-fatal-infos ."
    cd apps/driver_app && flutter test
    cd apps/passenger_app && flutter test

ci-local: ci-guards ci-flutter ci-backend

bootstrap:
    dart run melos bootstrap

# Docker-only database lifecycle helper.
db-up:
    docker compose up -d postgres-db
    @echo "PostgreSQL container started; see POSTGRES_HOST_PORT in .env for the host port."

# Docker-only database lifecycle helper.
db-down:
    docker compose stop postgres-db

# Docker-only infrastructure helpers. Native dependencies are intentionally
# not started by Just; start PostgreSQL, Redis, and RabbitMQ separately.
infra-up:
    docker compose up -d --remove-orphans --wait --wait-timeout 60 postgres-db redis rabbitmq

# Apply the single Ent migration stream to the configured native PostgreSQL.
db-migrate:
    cd server && go run ./cmd/migrate

# Apply the migration stream to Docker Compose PostgreSQL instead.
docker-db-migrate: infra-up
    @./scripts/database/migrate.sh

test-services:
    cd server && go test ./...

# Start the single Go application natively. PostgreSQL, Redis, and RabbitMQ
# must already be running on the host; this recipe never enables or starts them.
server:
    @port="{{ api-port }}"; \
    port_in_use() { \
        if command -v lsof >/dev/null 2>&1 && lsof -nP -t -iTCP:"$$1" -sTCP:LISTEN >/dev/null 2>&1; then return 0; fi; \
        if command -v fuser >/dev/null 2>&1 && fuser -n tcp "$$1" >/dev/null 2>&1; then return 0; fi; \
        return 1; \
    }; \
    stop_port() { \
        if command -v lsof >/dev/null 2>&1; then \
            pids="$$(lsof -nP -t -iTCP:"$$1" -sTCP:LISTEN 2>/dev/null || true)"; \
            if [ -n "$$pids" ]; then \
                for pid in $$pids; do kill -TERM "$$pid" 2>/dev/null || true; done; \
                return; \
            fi; \
        fi; \
        if command -v fuser >/dev/null 2>&1; then fuser -k -TERM -n tcp "$$1" >/dev/null 2>&1 || true; fi; \
    }; \
    if port_in_use "$$port"; then \
        echo "Stopping the existing process on TCP port $$port"; \
        stop_port "$$port"; \
        for attempt in 1 2 3 4 5; do \
            if ! port_in_use "$$port"; then \
                break; \
            fi; \
            sleep 1; \
        done; \
        if port_in_use "$$port"; then \
            echo "TCP port $$port is still in use; refusing to start the API."; \
            exit 1; \
        fi; \
    fi
    cd server && go run ./cmd/api

native-server: server

# Backward-compatible local startup alias.
start-all: server

# Start every application and dependency through Docker Compose explicitly.
docker-start-all: services-up

# Docker-only service lifecycle for the whole team.
services-up:
    @./scripts/script.sh --start

services-down:
    @./scripts/script.sh --stop

services-status:
    @./scripts/script.sh --status

services-logs:
    @./scripts/script.sh --logs

# Reverse ports for all connected Android devices/emulators
adb-reverse:
    @./scripts/adb_reverse.sh

# Backward-compatible Docker aliases.
docker-up: services-up

docker-down: services-down

# Build or rebuild compose images
docker-build:
    docker compose build postgres-db redis rabbitmq api

# View logs for all Docker services.
docker-logs: services-logs

generate-ent:
    cd server && go generate ./ent/generate.go
