# EasyRide backend architecture

EasyRide uses one Go core process for transactional REST operations and one Go
realtime process for WebSockets and ephemeral location. The API gateway and the
old Bun services are retired; mobile and Admin traffic reaches `core-api`
directly through deployment routing.

## Runtime layout

```text
server
  cmd/core-api
  cmd/entgenerate
  cmd/migrate
  cmd/realtime-service
  internal
    auth/schema       # identity Ent declarations owned by auth
    users/schema
    driver_doc/schema
    rides/schema
    location
    admin/schema
    realtime
    platform
  ent                 # generated client and migration API only
```

`core-api` owns authentication, users, driver documents, rides, bidding, fare,
location search, and Admin operations. `realtime-service` owns the WebSocket
connection lifecycle, chat relay, presence, and high-frequency driver location.
It does not own transactional ride state.

Each `server/internal/<domain>` package is private and owns its domain models,
use cases, adapters, transports, tests, and Ent schema declarations. Domain
packages do not import HTTP, Redis, Mapbox, or Ent into invariants. Adapters
translate external systems, transports validate requests and map responses, and
use cases define authorization and transaction boundaries.

Schemas are intentionally not stored in a global `server/ent/schema` directory.
The module-owned files under `internal/*/schema` are composed into one temporary
generation package by `cmd/entgenerate`. Ent still produces one typed client and
one PostgreSQL migration stream, which keeps cross-domain transactions possible
without recreating the old service split.

PostgreSQL is the source of truth. Redis is for ephemeral realtime state. Money
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

The deployment exposes one REST process and one realtime process:

```text
REST /api/*  -> core-api:8080
WS   /ws     -> realtime-service:8081
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
