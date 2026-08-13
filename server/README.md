# Go backend

This directory contains the Go backend. `core-api`, `realtime-service`, and
`api-gateway` are the three Go applications.
Domain-owned schemas under `internal/*/schema` are composed into one generated
Ent client.

## Run locally without Docker

```sh
cd server
go run ./cmd/core-api
go run ./cmd/realtime-service
go run ./api-gateway
```

`core-api` uses `CORE_API_PORT` and `MAPBOX_ACCESS_TOKEN`. The realtime process
uses `JWT_SECRET`; clients authenticate WebSocket upgrades with an
`Authorization: Bearer <token>` header.

## Run on Windows with Docker Desktop

The Compose file starts the backend and its required services: PostgreSQL,
Redis, RabbitMQ, `core-api`, `realtime-service`, and `api-gateway`. Only the
gateway is the public API; the core and realtime services stay on Docker's
internal network.

### Prerequisites

1. Install and start [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
2. In Docker Desktop settings, use Linux containers (the default) and allow the
   drive containing this repository to be shared if Docker Desktop asks.
3. Open PowerShell in the repository root.

### First start

```powershell
Copy-Item .env.example .env
notepad .env
docker compose up --build -d postgres-db redis rabbitmq core-api realtime-service api-gateway
docker compose ps
Invoke-RestMethod http://localhost:8000/health
```

Before starting, replace `JWT_SECRET` in `.env` with a private value of at
least 32 characters. Add `MAPBOX_ACCESS_TOKEN` to enable location search and
routing. SMTP values are only needed when testing verification emails.

The health command should return an object whose service is `api-gateway`.
API requests should use `http://localhost:8000/api/v1/...`.

### Optional admin web app

Start the admin app after the API is running:

```powershell
docker compose up --build -d admin-app
```

Then browse to `http://localhost:5173`.

### Everyday commands

```powershell
# Follow backend logs
docker compose logs -f api-gateway core-api realtime-service

# Rebuild after server code changes
docker compose up --build -d core-api realtime-service api-gateway

# Stop containers but preserve the PostgreSQL database
docker compose down

# Stop containers and permanently delete the local database
docker compose down --volumes
```

### Host ports

| Service | Host port | Purpose |
| --- | --- | --- |
| API gateway | `8000` | Public API endpoint |
| Admin app (optional) | `5173` | Admin web interface |
| PostgreSQL | `55432` | Direct database access for local tooling |
| Redis | `6379` | Local cache/real-time inspection |
| RabbitMQ | `5672` | Local message-broker inspection |

Change the corresponding values in `.env` if any of those ports are already
in use. PostgreSQL data is stored in the Docker-managed `postgres-data` volume,
so it survives normal `docker compose down` commands.

## Verify

```sh
cd server
go generate ./ent/generate.go
go test ./...
go vet ./...
```

The generated Ent files are checked into the repository. Schema changes must be
reviewed with their additive PostgreSQL migration before they are used by a
shared environment.
