# Security Domains and OWASP Crosswalk

Use ASVS 5.0.0 as the verification baseline, API Security Top 10 2023 as the API risk vocabulary, Cheat Sheets for remediation, and WSTG for authorized verification ideas. Verify exact identifiers before including them in a report.

## Input handling and secure coding

Check JSON decoders, request body limits, unknown fields, string/array/pagination bounds, coordinate ranges, enum/state validation, path IDs, query encoding, response headers, log fields, and canonicalization. Review Go handlers, Dart remote data sources, TypeScript form actions, and WebSocket event parsers.

## Authentication and session

Check JWT algorithm/key/claim/expiry validation, secret loading, password hashing, OTP entropy/TTL/attempts/single-use/purpose, reset flows, token storage, revocation, session fixation, and cookie flags. Trace verified identity from middleware into every handler and repository call.

## Authorization

Check object-level, function-level, and property-level controls for passengers, drivers, admins, rides, bids, chats, telemetry, documents, reviews, profiles, fares, and wallet records. Reject client-supplied role/owner IDs as authority. Verify state transitions and participant membership server-side.

## Cryptography and secrets

Check `crypto/rand`, password KDFs, constant-time comparisons, TLS configuration, JWT key strength/rotation, Mapbox/provider tokens, Flutter secure storage, environment files, CI logs, Docker build layers, and error/log output. Never treat a public Flutter token as a server secret, and never expose server secrets to clients.

## API security and resource consumption

Check gateway inventory and route allow-listing, private upstream exposure, CORS, security headers, forwarded headers, auth middleware placement, request/response limits, timeouts, rate limiting, retries, idempotency, WebSocket origin/authentication, pagination, provider fan-out, and unbounded goroutines.

## File handling

Check driver document upload size, content/MIME validation, filenames, path traversal, symlinks, permissions, object/storage keys, download authorization, metadata leakage, and retention. Verify that Redis-backed storage cannot be addressed by attacker-controlled paths or IDs without authorization.

## Data protection and privacy

Check location history, precise coordinates, phone/email, identity documents, financial/fare data, chat, JWTs, OTPs, provider responses, analytics, logs, CSV exports, browser payloads, and Flutter local storage. Verify data minimization, role filtering, retention, and generic client errors.

## Configuration and deployment

Check `.env` handling, required secrets, fail-closed startup, default credentials, service bindings, Docker ports, gateway exposure, TLS/HSTS, CORS origins, database/Redis/RabbitMQ authentication, health checks, migration ordering, debug logging, and dependency pinning.

## Concurrency and resilience

Check race-prone maps/caches, rate/idempotency stores, WebSocket registries, background telemetry, ride assignment, bid acceptance, wallet/fare transactions, queue consumers, context cancellation, resource closing, retry storms, circuit breakers, and failure atomicity.

## Client-side contract and platform security

Check API base URL configuration, route extras/deep links, Dio logging, auth interceptors, secure storage, background services, location permissions, Mapbox tokens, error rendering, and client-side checks that might be mistaken for authorization. Client checks improve UX; server checks enforce security.
