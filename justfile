set dotenv-load
set export

api-port := env_var("API_PORT")
minio-host-port := env_var_or_default("MINIO_HOST_PORT", "9000")

default:
    @just --list

clean:
    flutter clean
    flutter pub get

update:
    flutter pub upgrade

analyze:
    dart run melos exec -- "flutter analyze --no-fatal-infos ."

server-unit:
    cd server && go test -count=1 -shuffle=on ./...

server-race:
    cd server && go test -count=1 -race ./...

ci-guards:
    git diff --check

ci-backend:
    cd server && go mod download
    cd server && go mod verify
    cd server && go tool sqlc generate
    cd server && go mod tidy -diff
    cd server && go vet ./...
    cd server && go test -count=1 -shuffle=on ./...
    cd server && go test -count=1 -race ./...
    cd server && go test -count=1 -tags=integration ./...
    cd server && go test -count=1 -race -tags=integration ./...

ci-flutter:
    flutter pub get
    dart run melos bootstrap
    dart format --set-exit-if-changed apps packages
    dart run melos exec -- "flutter analyze --no-fatal-infos ."
    cd apps/driver && flutter test
    cd apps/passenger && flutter test

ci-local: ci-guards ci-flutter ci-backend

bootstrap:
    dart run melos bootstrap

db-up:
    docker compose up -d postgres-db
    @echo "PostgreSQL container started; see POSTGRES_HOST_PORT in .env for the host port."

db-down:
    docker compose stop postgres-db

infra-up:
    docker compose up -d --remove-orphans --wait --wait-timeout 60 postgres-db redis minio

db-migrate:
    cd server && go run ./cmd/migrate

docker-db-migrate: infra-up
    @./scripts/database/migrate.sh

objectstorage-migrate:
    docker compose --profile ops run --rm objectstorage-migrate

test-services:
    cd server && go test ./...

server action="":
    @case "{{ action }}" in \
        "") exec just native-server ;; \
        "--start") exec ./scripts/script.sh --start ;; \
        "--stop") exec ./scripts/script.sh --stop ;; \
        *) echo "Usage: just server [--start|--stop]" >&2; exit 2 ;; \
    esac

native-server:
    @docker compose stop api >/dev/null 2>&1 || true
    @just infra-up
    @port="{{ api-port }}"; \
    port_in_use() { \
        if command -v lsof >/dev/null 2>&1 && lsof -nP -t -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; then return 0; fi; \
        if command -v fuser >/dev/null 2>&1 && fuser -n tcp "$1" >/dev/null 2>&1; then return 0; fi; \
        return 1; \
    }; \
    stop_port() { \
        if command -v lsof >/dev/null 2>&1; then \
            pids="$(lsof -nP -t -iTCP:"$1" -sTCP:LISTEN 2>/dev/null || true)"; \
            if [ -n "$pids" ]; then \
                for pid in $pids; do kill -TERM "$pid" 2>/dev/null || true; done; \
                return; \
            fi; \
        fi; \
        if command -v fuser >/dev/null 2>&1; then fuser -k -TERM -n tcp "$1" >/dev/null 2>&1 || true; fi; \
    }; \
    if port_in_use "$port"; then \
        echo "Stopping the existing process on TCP port $port"; \
        stop_port "$port"; \
        for attempt in 1 2 3 4 5; do \
            if ! port_in_use "$port"; then \
                break; \
            fi; \
            sleep 1; \
        done; \
        if port_in_use "$port"; then \
            echo "TCP port $port is still in use; refusing to start the API."; \
            exit 1; \
        fi; \
    fi
    cd server && MINIO_ENDPOINT="127.0.0.1:{{ minio-host-port }}" go run ./cmd/api

start-all: native-server

docker-start-all: services-up

services-up:
    @./scripts/script.sh --start

services-down:
    @./scripts/script.sh --stop

services-status:
    @./scripts/script.sh --status

services-logs:
    @./scripts/script.sh --logs

adb-reverse:
    @./scripts/adb_reverse.sh

docker-up: services-up

docker-down: services-down

docker-build:
    docker compose build postgres-db redis migrate api

docker-logs: services-logs

generate-sqlc:
    cd server && go tool sqlc generate
