# Go backend

This directory contains the Go backend described in `docs/architecture.md`.
`core-api`, `realtime-service`, and `api-gateway` are the three Go applications.
Domain-owned schemas under `internal/*/schema` are composed into one generated
Ent client.

## Run

```sh
cd server
go run ./cmd/core-api
go run ./cmd/realtime-service
go run ./api-gateway
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
