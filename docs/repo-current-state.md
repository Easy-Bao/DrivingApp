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

The public gateway and both backend applications now apply Redis-backed rate
limits, request IDs, CORS/security headers, control-character target checks,
and global request-body limits. State-changing Flutter requests carry an
idempotency key; the backend stores successful responses in Redis for replay.
Mapbox and go-mail calls use circuit breakers. Request logs include status,
request ID, client IP, user agent, and selected security-event classifications
without request bodies or credentials.

Ride creation, bid sessions, fare estimates, and final-fare responses now use
the server's Mapbox route metrics in production; client distance and duration
are treated as untrusted hints. Passenger offer acceptance is authorized as a
passenger action and binds the selected driver transactionally. Redis GEO
telemetry rejects invalid coordinates and unbounded search radii. Both Flutter
clients animate only server-returned route geometry, and driver trip maps leave
missing coordinates unrouted instead of rendering a fabricated `(0,0)` point.
Cash settlement, capacity, active-booking, review-participant, and duplicate
bid checks remain server-authoritative.

The API deliberately does not use SQLi/XSS keyword blacklists or mobile-app
HMAC signatures: Ent parameterization, strict DTO validation, JSON encoding,
TLS, and JWTs provide the meaningful controls, while an embedded mobile secret
cannot prove that a request came from an official compiled app. The Ent audit
table exists, but durable append-only audit writes and fraud-specific signals
remain follow-up work.
