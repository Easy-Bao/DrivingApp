# EasyRide backend architecture

EasyRide uses three Go applications: `core-api` for transactional REST,
`realtime-service` for WebSockets and ephemeral driver location/chat, and
`api-gateway` for routing and edge infrastructure. The old Bun microservice
fleet is retired.

## Runtime layout

```text
server
  cmd/core-api
  cmd/realtime-service
  cmd/entgenerate
  cmd/migrate
  api-gateway
  internal
    auth/schema       # identity Ent declarations owned by auth
    users/schema
    driver_doc/schema
    rides/schema
    location
    admin/schema
    realtime
    platform
  tests                 # module contract and integration tests
  ent                 # generated client and migration API only
```

`core-api` owns authentication, users, driver documents, rides, bidding, fare,
location search, nearby POIs, reverse geocoding, routing, and Admin operations. `realtime-service` owns the WebSocket
connection lifecycle, Redis-backed presence/geo, and live chat relay. It does
not own transactional ride state. `api-gateway` contains no business logic.

Each `server/internal/<domain>` package is private and owns its domain models,
use cases, adapters, transports, and module tests. Domain packages do not import
HTTP, Redis, Mapbox, or Ent into invariants. Adapters translate external
systems, transports validate requests and map responses, and use cases define
authorization and transaction boundaries. `cmd` packages only perform DI and
process startup.

Schemas are intentionally not stored in a global `server/ent/schema` directory.
The module-owned files under `internal/*/schema` are composed into one temporary
generation package by `cmd/entgenerate`. Ent still produces one typed client and
one PostgreSQL migration stream, which keeps cross-domain transactions possible
without recreating the old service split.

PostgreSQL is the source of truth. Redis is for ephemeral realtime state and
location-result caching; RabbitMQ carries optional location-domain events. Money
is stored as integer centavos and all assignment or money mutations must be
idempotent. `server/cmd/migrate` runs Ent's additive schema migration; local and
CI entry points call `scripts/database/migrate.sh`. No Drizzle command or
`db:push` remains.

Generate and verify the graph with:

```sh
cd server
go generate ./ent/generate.go
go test ./...
go vet ./...
```

The generated files under `server/ent` are checked in and must not be edited by
hand. Schema changes are reviewed with the generated migration contract before
deployment. The application does not run destructive drop options.

The deployment exposes three applications:

```text
REST /api/*  -> api-gateway -> core-api:8080
WS   /ws     -> api-gateway -> realtime-service:8081
```

Core endpoint groups are `/auth`, `/users`, `/driver/documents`, `/rides`,
`/location`, and `/admin`. Health is `GET /health`. Realtime clients use one
authenticated WebSocket connection for location, presence, bid notifications,
and chat events.

The legacy service trees and `server/database` are removed only in the cutover
that changes Compose, startup, CI, and migration scripts together. This checkout
completes the structural cutover and Ent migration substrate; endpoint-by-
endpoint business parity remains the next implementation slice for the
currently skeletal Go modules.
