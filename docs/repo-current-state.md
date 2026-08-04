# Repository current state

The backend cutover is complete: the old Bun/Drizzle service fleet and
`server/database` tree are gone. The backend now contains `core-api`,
`realtime-service`, and `api-gateway`, with one public gateway endpoint and
private upstream processes.

The core modules have domain-owned schemas and ports/adapters for PostgreSQL,
Redis, RabbitMQ, Mapbox, go-mail, and document persistence. Auth includes explicit
passenger/driver registration and authentication use cases, Redis-backed
pending passenger registration, passenger-only OTP verification, password
reset, JWT issuance, and profile provisioning. Rides
contains fare calculation, persisted bid sessions/offers, transactional offer
acceptance, the ride state machine, passenger history, driver
activity/reviews, and online-driver discovery. Realtime contains Redis-backed
GEO and telemetry plus Redis-backed WebSocket chat relay and room history.

The generated Ent client and platform schema aggregate are checked in because
they are required at runtime; module schemas are the only business-schema
source files. `scripts/database/migrate.sh`, `justfile`, Compose, and CI all
use the same migration command.

The Flutter workspace has exactly `shared_core` and `shared_ui`; the former
contains the consolidated models and network/location/fare/realtime utilities,
while the latter contains reusable presentation components. App themes remain
in the two client applications.
