# EasyRide Backend and App Architecture

This is the target architecture for the Passenger app, Driver app, Admin portal,
and backend. It is a migration target, not a description of the current
checkout. The current backend is still split across Bun, Hono, and Drizzle
services.

## Architecture Decision

Use a modular core monolith with a separate realtime process:

- `core-api` owns transactional business operations and the public REST API.
- `realtime-service` owns long-lived WebSocket connections and fast location
  updates.
- Both processes live in one Go repository and use explicit package boundaries.
- The API gateway is deployment infrastructure. It is not another business
  service.
- PostgreSQL remains the source of truth. Redis is used for ephemeral location,
  presence, and socket coordination data.

This is not a microservice architecture. The realtime process is separate only
because persistent connections and high-frequency GPS traffic have different
runtime characteristics from ride and account transactions.

## Server Layout

```text
server
  go.mod
  cmd
    core-api
      main.go
    realtime-service
      main.go
  internal
    auth
      adapter
        postgres
        sms
        token
      domain
        errors.go
        identity.go
        ports.go
      transport
        http
          routes.go
          handler.go
      usecase
        request_otp.go
        verify_otp.go
        refresh_session.go
    users
      adapter
        postgres
      domain
        user.go
        driver_profile.go
        passenger_profile.go
        ports.go
      transport
        http
          routes.go
          handler.go
      usecase
        get_me.go
        update_profile.go
        update_driver_profile.go
    driver-docs
      adapter
        object_storage
        postgres
      domain
        document.go
        verification.go
        ports.go
      transport
        http_driver
          routes.go
          handler.go
        http_admin
          routes.go
          handler.go
      usecase
        submit_document.go
        get_status.go
        review_document.go
    rides
      adapter
        postgres
      domain
        ride.go
        bid.go
        fare.go
        state.go
        ports.go
      transport
        http
          routes.go
          handler.go
      usecase
        estimate_fare.go
        request_ride.go
        submit_bid.go
        accept_bid.go
        start_ride.go
        complete_ride.go
        cancel_ride.go
    location
      adapter
        mapbox
        postgres
      domain
        place.go
        coordinates.go
        ports.go
      transport
        http
          routes.go
          handler.go
      usecase
        search_places.go
        reverse_geocode.go
    admin
      adapter
        postgres
      domain
        audit_event.go
        ports.go
      transport
        http
          routes.go
          handler.go
      usecase
        get_overview.go
        record_audit_event.go
    realtime
      chat
        domain
          message.go
        usecase
          relay_message.go
      geo
        adapter
          redis.go
        domain
          driver_point.go
        usecase
          ingest_location.go
          find_nearby_drivers.go
      ws
        handler.go
        hub.go
    platform
      config
      http
        auth_middleware.go
        error_response.go
      postgres
      redis
      storage
      clock
  ent
    schema
      user.go
      driver_profile.go
      driver_document.go
      ride.go
      bid.go
      audit_event.go
    ent.go
    generate.go
  database
    migrations
  api-gateway
    README.md
```

## Folder Responsibilities

`server` - Go backend repository and module boundary.

`server/cmd` - Executable entry points. These files only load configuration,
construct adapters, wire use cases, register routes, and start a process.

`server/cmd/core-api` - Starts the REST API and wires the transactional modules.

`server/cmd/realtime-service` - Starts the WebSocket server and wires Redis,
geo, chat, and connection management.

`server/internal` - Private application code. Packages below this directory
cannot be imported by external Go modules.

`internal/auth` - Shared identity, OTP, session, refresh, and token rules for
both mobile apps. It does not contain Driver document verification.

`internal/users` - User identity and role-specific passenger or driver profile
data. A driver is a user with a driver profile, not a second authentication
system.

`internal/driver-docs` - Driver document submission and verification as a
separate business domain. Driver and Admin transports call the same use cases.

`internal/rides` - Fare estimation, ride requests, bidding, and ride state
transitions. Acceptance and assignment must run in one PostgreSQL transaction.

`internal/location` - Low-frequency place search, reverse geocoding, and route
lookup used by REST flows. It does not own live driver GPS streams.

`internal/admin` - Admin-specific reports, audit actions, and operational
queries. It may call a Driver Document use case, but does not copy document or
driver tables.

`internal/realtime` - Code used only by the realtime process. It is not a
second ride service and must not become a place for transactional ride rules.

`internal/realtime/geo` - Ephemeral driver presence and coordinates in Redis.
It should publish validated events or call a narrow core API port when a live
event needs a transactional side effect.

`internal/realtime/chat` - Live message validation and routing. Message history
and authorization-sensitive persistence belong behind an explicit port rather
than in the WebSocket hub.

`internal/realtime/ws` - WebSocket protocol and connection lifecycle. It owns
transport concerns, not business decisions.

`internal/platform` - Infrastructure shared by the two processes: config,
logging, PostgreSQL, Redis, object storage, clock, and HTTP middleware. It is
not a place for domain models or cross-module business services.

`server/ent/schema` - Ent schema declarations for the single PostgreSQL graph.
Schemas can be grouped by domain in separate files, but generated Ent code and
migrations are produced from one graph. Each module owns the schema files for
its tables and exposes narrow repository ports to other modules.

`server/database/migrations` - Reviewed, additive SQL migrations generated or
maintained for deployment. Never use `db:push` against shared environments.

`server/api-gateway` - Reverse-proxy configuration and deployment notes. It
routes `/api/*` to `core-api` and `/ws/*` to `realtime-service`; it contains no
ride, auth, or user logic.

## Hexagonal Rules

Every business module follows the same four areas without adding layers that do
not have a job:

`domain` - Entities, value objects, invariants, domain errors, and outbound port
interfaces. This package does not import Ent, Hono, HTTP, Redis, or Mapbox.

`usecase` - Application operations. It coordinates domain rules and ports,
handles authorization decisions that belong to the operation, and defines
transaction boundaries.

`adapter` - Outbound implementations such as Ent repositories, Redis, SMS,
Mapbox, and object storage. Adapters translate external data into domain types.

`transport` - Inbound adapters such as HTTP handlers and WebSocket handlers.
Transport validates input, derives identity from verified credentials, calls a
use case, and maps the result to a protocol response.

Do not create interfaces for every function. Add a port when the dependency is
external, replaceable, transaction-sensitive, or needed for focused tests.

## Ent and Multiple Schemas

The Go dependency is `entgo.io/ent`. Ent is a suitable replacement for the
current Drizzle layer during the Go migration, but it does not mean creating one
database client per old service.

- Use one Ent graph and one migration stream for the core PostgreSQL database.
- Keep schema declarations near their owning domain in `ent/schema`.
- Generate one typed client used by adapter packages.
- Keep repositories behind module-owned ports so modules do not query each
  other's tables directly.
- Use explicit Ent transactions for ride creation, bid acceptance, assignment,
  and other state-changing operations.
- Keep realtime location data in Redis; do not write every GPS ping to Ent.
- If a future domain genuinely needs a separate database, give it a separate
  Ent graph and deployment boundary then, rather than designing for that now.

The migration should be incremental: freeze new Drizzle features, define the
Go contracts, migrate one vertical slice, verify it against PostgreSQL, then
retire the corresponding TypeScript service. Do not run two writers against the
same tables without an explicit cutover plan.

## Flutter Package Boundaries

```text
packages
  shared_core
    pubspec.yaml
    lib
      shared_core.dart
      src
        api
        models
        realtime
        storage
        constants
  shared_ui
    pubspec.yaml
    lib
      shared_ui.dart
      src
        components
        maps
        tokens
        accessibility
apps
  passenger_app
    lib
      src
        core
          theme
          config
        features
  driver_app
    lib
      src
        core
          theme
          config
        features
```

`packages/shared_core` - Shared API models, HTTP client contracts, WebSocket
protocol types, secure token storage abstractions, and transport utilities.
It must not contain Passenger screens, Driver onboarding rules, or app-specific
navigation.

`packages/shared_ui` - Reusable controls, map primitives, spacing, typography
roles, accessibility helpers, and visual tokens. It must not expose one global
`AppTheme` for both products.

`apps/passenger_app/lib/src/core/theme` - Passenger theme composition. It maps
shared tokens to Passenger colors, navigation styling, and passenger-specific
component themes.

`apps/driver_app/lib/src/core/theme` - Driver theme composition. It can use the
same typography and component contracts while choosing independent colors,
density, navigation, and operational states.

The two apps may share a token name such as `surfacePrimary` without sharing
the value. Shared UI components should consume `ThemeData` or explicit theme
extensions supplied by the app, not import Passenger or Driver theme files.

## Public Entry Points

```text
REST  https://api.easybao.com/api/v1
WS    wss://realtime.easybao.com/ws
```

Core REST routes are grouped by business capability:

```text
POST   /auth/otp
POST   /auth/verify
GET    /users/me
PATCH  /users/me
POST   /driver/documents
GET    /driver/documents/status
PATCH  /admin/documents/{id}/review
GET    /location/search
GET    /location/reverse
POST   /rides/estimate
POST   /rides
POST   /rides/{id}/bids
POST   /bids/{id}/accept
```

The WebSocket protocol carries location, presence, bid notifications, and live
chat events over one authenticated connection. REST remains the authority for
state-changing ride and document operations.

## Migration Order

1. Define the public contracts and common error format.
2. Create the Go module, platform packages, Ent graph, and additive migration
   workflow without changing production writers.
3. Migrate auth and users as one identity slice.
4. Migrate driver documents and expose separate Driver and Admin transports.
5. Migrate location search, then move live location ingestion to Redis and the
   realtime process.
6. Migrate rides, fare, and bidding together so transactional invariants remain
   in one use case and database transaction.
7. Move chat history and live relay behind explicit ports.
8. Switch the gateway and clients, observe the new path, then retire old
   services and Drizzle writers one slice at a time.

Until these steps are complete, the existing Hono services and Drizzle schemas
remain active and should not be described as migrated.
