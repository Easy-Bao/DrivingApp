# Go backend

This directory is the migration target for the backend. It currently contains
the first Go slice of the modular architecture:

- `cmd/core-api` exposes location REST routes and a health endpoint.
- `cmd/realtime-service` exposes authenticated WebSocket event transport.
- `ent/schema` is the source for the shared PostgreSQL Ent graph.
- `internal` contains domain code behind transport and adapter boundaries.

The existing Bun services and `location-service` remain in the repository while
their behavior is migrated and verified. Do not remove or point production
traffic at a replacement slice without completing its contract and cutover
checks.

## Run

```sh
cd server
go run ./cmd/core-api
go run ./cmd/realtime-service
```

`core-api` uses `CORE_API_PORT` and `MAPBOX_ACCESS_TOKEN`. The realtime process
uses `JWT_SECRET`; clients authenticate WebSocket upgrades with an
`Authorization: Bearer <token>` header.

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
