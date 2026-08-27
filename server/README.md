# Go backend

This directory contains the Go modular monolith. The `internal/*` packages
own the business modules and their ports/adapters; `cmd/api` is the single
long-running application process that composes HTTP, WebSocket, persistence,
transient event delivery, and infrastructure adapters.

The other commands are one-shot developer tools:

- `cmd/migrate` applies the ordered, advisory-locked migration plan.
- `cmd/entgenerate` regenerates the Ent client.

## Native local development (default)

The native workflow expects PostgreSQL and Redis to be installed and started
separately. Just does not enable, start, or stop those services.

1. Copy `.env.example` to `.env` and set the native database credentials,
   `DATABASE_URL`, and a JWT secret.
2. Start the configured native dependencies when you are ready to use them.
3. Start the Go application:

```sh
just server
```

This runs the equivalent of:

```sh
cd server
go run ./cmd/api
```

The public client URL is `API_BASE_URL`, normally `http://127.0.0.1:8000`.
The API process owns REST, WebSocket, authentication, rides, location,
realtime, chat, and admin routes.

Realtime events and the small assignment routing projection stay in memory for
the single-process deployment. PostgreSQL remains the authorization authority;
clients recover transient delivery gaps through REST snapshots. Redis is kept
for high-churn location state, provider caching, authentication workflow
artifacts, and request protection rather than as a required event broker.
Driver GEO members are swept from a companion expiry index, and passenger
coordinates expire automatically after a short active-ride window.

The API performs a read-only Ent schema preflight before listening. Docker
Compose runs the migration binary after PostgreSQL is healthy and does not
start the API until that migration process exits successfully. Native startup
still requires `just db-migrate` to be run explicitly.

### Runtime protection and connection pools

Request limits use independent one-minute buckets so polling cannot consume an
active trip's telemetry allowance. Authentication defaults to 10 requests,
external location queries to 60, fare queries to 30, WebSocket connection
attempts to 30, telemetry to 600, other mutations to 120, and reads to 300.
Health checks and CORS preflight requests bypass the limiter. Public auth,
location, fare, and connection protection fails closed when Redis is
unavailable; authenticated reads, mutations, and telemetry continue to their
own handlers so a protection-store outage does not stop an active ride.

`TRUSTED_PROXY_CIDRS` is empty by default. Set it only to the exact proxy
networks that are allowed to supply forwarded client and protocol headers.
Headers sent by direct clients are discarded. This prevents address spoofing
without grouping every deployed user under a known reverse proxy's address.

The API uses one PostgreSQL handle for startup health checking and Ent. The
pool defaults to 25 open and 10 idle connections, with a 30-minute connection
lifetime, a 5-minute idle lifetime, and a 5-second startup ping timeout. Tune
these using the `POSTGRES_*` values documented in `.env.example`; keep the idle
connection count no greater than the open connection count.

`REPORTING_TIMEZONE` defines the calendar day used by driver dashboard and
earnings summaries. It defaults to `Asia/Manila`; set an IANA timezone name
explicitly in every environment so native and container deployments report the
same daily totals.

Idempotency protection is limited to durable domain commands such as ride,
bid, profile, review, and chat mutations. Authentication, fare and location
queries, telemetry, online-presence updates, and binary document uploads do
not use the replay store. The shared mobile interceptor follows the same rule.

To apply the additive migration plan against native PostgreSQL:

```sh
just db-migrate
```

The long-running API process never changes the database schema. Run the
migration command once for each deployment before starting or replacing API
instances. Applied versions are recorded in `schema_migrations`; incompatible
legacy identifier types are rejected with an actionable error instead of being
renamed during application startup.

### Bounded read contracts

Trip history and passenger notifications use `limit` and `offset` query
parameters and return a stable envelope:

```json
{"items": [], "has_more": false, "next_offset": null}
```

Driver dashboard recovery uses `GET /api/v1/drivers/{id}/trips?scope=active`
instead of downloading completed history. Driver earnings use the dedicated
`GET /api/v1/drivers/{id}/earnings` summary, which projects only current-month
completion and payout fields. Passenger weekly activity totals come from
`GET /api/v1/passengers/{id}/activity-summary`, so they remain authoritative
when ride cards span multiple pages.

Passenger nearby-driver lookup first reads the bounded telemetry candidates,
then requests profiles for those IDs through `GET /api/v1/drivers/online?ids=`.
`POST /api/v1/location/matrix` accepts one origin and at most ten destinations
and returns `distances_km` and `durations_min`; it performs one provider matrix
request for multiple destinations and a directions request for one destination.

### Private uploads

Driver documents and passenger avatars are immutable private objects stored in
PostgreSQL through the Ent object-store adapter. Feature tables retain only
ownership, workflow, and content metadata; the binary data never uses a local
filesystem directory or Redis as a source of truth. Authorized endpoints read
objects only after the owning feature verifies the requesting identity.

`POST /api/v1/driver/documents?type=driver_license` accepts a raw PDF, JPEG, or
PNG body. The supported type values are `driver_license`,
`vehicle_registration`, `vehicle_insurance`, and `government_id`. The declared
media type must match the detected file signature; object size and checksum are
recorded with the immutable revision.

Drivers can list their own status and download only their own revisions.
Configured administrators can page the review queue, download a private object,
and make one final approve-or-reject decision:

- `GET /api/v1/driver/documents/status`
- `GET /api/v1/driver/documents/{id}/content`
- `GET /api/v1/admin/documents?status=pending&limit=25&offset=0`
- `GET /api/v1/admin/documents/{id}/content`
- `PATCH /api/v1/admin/documents/{id}/review` with
  `{"status":"approved"}` or `{"status":"rejected"}`

Content responses are attachments with `Cache-Control: private, no-store`.
Metadata responses never expose private object keys or checksums.

## Optional Docker Compose workflow

Docker Compose remains available for contributors who need the containerized
environment. It is not used by `just server` or `just start-all`.

### Run on Windows with Docker Desktop

The Compose file starts PostgreSQL, Redis, a one-shot migration checkpoint, the
single `api` process, and the optional admin app. The API container is the
public HTTP and WebSocket entrypoint.

### Prerequisites

1. Install and start [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
2. In Docker Desktop settings, use Linux containers (the default) and allow the
   drive containing this repository to be shared if Docker Desktop asks.
3. Open PowerShell in the repository root.

### First start

```powershell
Copy-Item .env.example .env
notepad .env
docker compose up --build -d postgres-db redis migrate api
docker compose ps
Invoke-RestMethod http://localhost:8000/health
```

Before starting, set `POSTGRES_PASSWORD` and replace `JWT_SECRET` in `.env`
with private values; the JWT secret must be at least 32 characters. Add
`MAPBOX_ACCESS_TOKEN` to enable location search and routing. SMTP values are
only needed when testing verification emails.

The health command should return an object whose service is `api`.
The readiness command is `http://localhost:8000/readyz` and returns `503`
until PostgreSQL, Redis, and the generated Ent schema are available.
API requests should use `http://localhost:8000/api/v1/...`.

### Optional admin web app

Start the admin app after the API is running:

```powershell
docker compose up --build -d admin-app
```

Then browse to `http://localhost:5173`.

### Everyday commands

```powershell
# Follow API logs
docker compose logs -f api

# Rebuild after server code changes
docker compose up --build -d api

# Stop containers but preserve the PostgreSQL database and private uploads
docker compose down

# Stop containers and permanently delete the local database
docker compose down --volumes
```

### Host ports

| Service | Host port | Purpose |
| --- | --- | --- |
| API | `8000` | Public HTTP and WebSocket endpoint |
| Admin app (optional) | `5173` | Admin web interface |
| PostgreSQL | `55432` | Direct database access for local tooling |
| Redis | `6379` | Cache, location state, and request protection |

Change the corresponding values in `.env` if any of those ports are already
in use. PostgreSQL data is stored in the Docker-managed `postgres-data` volume
and survives a normal `docker compose down` command.

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
