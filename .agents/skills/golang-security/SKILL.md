---
name: golang-security
description: Security review, audit, and implementation guidance for this driving app's Go services, API gateway, authentication, rides and fares, telemetry, location providers, uploads, WebSockets, Redis, PostgreSQL, RabbitMQ, Docker, secrets, and dependency tooling. Use when reviewing or writing Go code that crosses HTTP, identity, persistence, messaging, filesystem, network, or configuration trust boundaries.
---

# Go Security for Driving App

## Mission

Protect the system at every trust boundary. Trace untrusted data from ingress to its sensitive operation, verify the existing defenses, then report or fix the smallest complete issue without exposing credentials or inventing runtime evidence.

Apply this skill to code under `server/`, gateway behavior, Go tests, Docker/service configuration, and client/server contracts where a Go-side security decision affects the Flutter apps. Keep Flutter-only concerns in the relevant Flutter security skills.

## Operating modes

- **Review:** Start with the changed files, then follow affected call sites and data flows across middleware, handlers, use cases, repositories, and clients. Do not stop at the diff.
- **Audit:** Cover five domains: injection and input handling; cryptography and secrets; HTTP/gateway and network security; authentication and authorization; concurrency, resilience, and dependency risk. Deduplicate findings before reporting.
- **Coding:** Confirm the trust boundary and intended invariant, implement a focused defense, add negative or regression coverage, and run the relevant checks.

For review or audit requests, do not change files unless the user also asks for fixes. Preserve existing uncommitted work and never commit, push, rotate secrets, deploy, or alter live data without explicit authorization.

## Application security map

- `server/api-gateway`: public reverse proxy, route ownership, forwarded headers, CORS, security headers, timeouts, and WebSocket forwarding.
- `server/cmd/core-api`: authentication, users, driver documents, location, rides, fares, bids, reviews, PostgreSQL/Ent, Redis, and RabbitMQ wiring.
- `server/cmd/realtime-service`: authenticated chat and geo/telemetry HTTP and WebSocket flows.
- `server/internal/auth` and `server/shared-core/security`: password hashing, JWT issuance and verification, OTP and pending-registration state.
- `server/internal/rides`: ride lifecycle, bidding, offers, fare snapshots, reviews, cash settlement, and participant authorization.
- `server/internal/location`: Mapbox requests, coordinate validation, route/matrix responses, cache behavior, and provider failure handling.
- `server/internal/driver_doc`: upload limits, document metadata, Redis-backed private storage, and admin review authorization.
- `server/shared-core/middleware`: rate limiting, idempotency, request size limits, logging, CORS/HSTS, and security middleware.

Treat `.env` files and environment variables as secrets/configuration inputs. Never print their values or add credentials to examples, tests, commits, prompts, or reports.

## Security workflow

### 1. Establish the boundary

Identify every source of attacker-controlled data: HTTP path/query/body/headers, WebSocket events, JWT claims, uploaded files, environment variables, Redis values, RabbitMQ messages, database rows, Mapbox responses, and forwarded proxy headers. Record the sink: SQL/Ent predicate, shell/process, URL request, filesystem path, template, crypto operation, authorization decision, log, or resource allocation.

Use `rg` first. Useful searches include:

```bash
rg -n "os\\.Command|exec\\.Command|QueryContext|\\.ExecContext|url\\.Parse|http\\.Get|http\\.NewRequest|filepath\\.|os\\.Open|os\\.WriteFile|jwt|password|OTP|Authorization|X-Forwarded|websocket|redis|rabbit" server
rg -n "os\\.Getenv|log\\.|Printf|Sprintf|fmt\\.Errorf|errors\\.New" server
```

Read the surrounding middleware and tests before reporting a finding. Upstream validation changes severity but does not eliminate the need for defense in depth.

### 2. Trace and threat-model

Apply STRIDE at each trust boundary:

- Spoofing: token forgery, weak secrets, OTP abuse, and WebSocket identity.
- Tampering: ride state, bids, fares, telemetry, uploaded documents, and idempotency keys.
- Repudiation: audit events and security-relevant logs without leaking secrets.
- Information disclosure: PII, location history, documents, tokens, and provider errors.
- Denial of service: body sizes, pagination, rate limits, provider calls, goroutines, queues, and WebSockets.
- Elevation of privilege: passenger/driver/admin role checks and resource ownership.

Follow identity from the verified token to the handler and repository. A client-supplied passenger, driver, ride, or admin ID is not an authority signal.

### 3. Classify findings

Score DREAD from 0–2 for Damage, Reproducibility, Exploitability, Affected users, and Discoverability. Sum the result and use these project priorities:

- **Critical (8–10):** RCE, credential theft, auth bypass, full data breach, or broken cryptography.
- **High (6–7.9):** privilege escalation, sensitive document/location exposure, serious integrity failure, or reliable DoS.
- **Medium (4–5.9):** limited disclosure, weak session/OTP controls, missing defense in depth, or bounded resource abuse.
- **Low (1–3.9):** minor disclosure or hardening gap with limited practical impact.

Do not report a pattern in isolation. State the data origin, defenses already present, exploit preconditions, impact, and what changes if an upstream defense is bypassed or removed. If an accepted upstream invariant makes a pattern safe, document the reason in a concise code comment when that decision could be re-litigated later.

## Required defenses

### Input and injection safety

- Decode JSON with body limits; reject unknown fields where the contract is security-sensitive.
- Bound strings, arrays, pagination, coordinates, route exclusions, file sizes, and WebSocket messages before expensive work.
- Use Ent predicates or parameterized SQL. Never concatenate user input into SQL, shell commands, log formats, HTML, or response headers.
- Never invoke a shell for user-controlled input. If a process is unavoidable, use `exec.Command` with a fixed executable and separate arguments.
- Validate latitude/longitude ranges, enum values, UUID/ID syntax, ride state transitions, and money units at the HTTP boundary and again at domain boundaries.
- Treat Redis and RabbitMQ payloads as untrusted serialized data; validate schema and authorization before acting on them.

### Authentication and authorization

- Load JWT and encryption secrets from environment/secret management; fail closed when required production secrets are absent or obviously weak.
- Use vetted password hashing already established by the service; never store plaintext passwords, OTPs, or reset tokens.
- Generate OTPs, reset tokens, idempotency material, and other secrets with `crypto/rand`; enforce TTL, attempt limits, single use, and purpose binding.
- Verify signature, issuer/audience where configured, expiration, subject, role, and token type before authorizing.
- Derive acting identity from verified claims. Enforce participant ownership on rides, bids, chats, telemetry, profiles, documents, reviews, and admin operations.
- Make state-changing ride, bid, fare, wallet, and document operations idempotent where retries can duplicate effects.
- Compare sensitive byte values with constant-time comparison when timing could reveal information.

### HTTP, gateway, and network security

- Keep the gateway as the only public API endpoint; allow-list routing to core and realtime services and do not trust client-supplied forwarding or role headers.
- Configure read-header, read, write, idle, provider, Redis, RabbitMQ, and WebSocket deadlines. Never leave attacker-reachable network calls unbounded.
- Keep CORS restrictive, HSTS environment-controlled for TLS deployments, and security headers enabled for browser-facing responses.
- Do not construct outbound URLs from arbitrary user input. Mapbox/provider hosts must be fixed or allow-listed; query values must be encoded structurally.
- Prevent SSRF, open redirects, proxy abuse, DNS rebinding assumptions, and accidental exposure of private upstreams.
- Validate WebSocket origin and authenticate the connection and every sensitive event; do not trust room IDs or driver IDs supplied by the client.

### Data, files, and messaging

- Keep database queries scoped by tenant/user/role and use transactions for ride assignment, fare snapshots, cash settlement, wallet ledgers, and review state.
- Prevent path traversal and symlink escapes for driver documents. Ignore client filenames for storage paths, enforce private permissions, size limits, MIME/content validation, and safe download authorization.
- Use Redis TTLs and bounded values for OTP, pending registration, cache, rate limit, idempotency, and location state. Never treat cached identity or authorization data as authoritative without verification.
- Authenticate and authorize RabbitMQ consumers, validate messages, bound retries, and avoid poison-message loops.
- Treat location history, phone/email data, identity documents, tokens, and financial records as sensitive; minimize retention and response fields.

### Errors and observability

- Return stable generic client errors. Log detailed diagnostics server-side without passwords, JWTs, OTPs, Mapbox tokens, database URLs, document contents, or unnecessary precise location data.
- Sanitize user-controlled log fields to prevent log injection and unbounded log amplification.
- Preserve correlation/request identifiers without allowing clients to overwrite security identity or inject response headers.
- Audit authentication, authorization failures, document access, ride assignment, fare/ledger changes, and admin actions with actor, target, result, and correlation data.

### Concurrency and resilience

- Run `go test -race ./...` for shared state, caches, rate limiting, idempotency, WebSocket registries, and background workers.
- Protect maps and mutable state with clear ownership, mutexes, or channels. Never start unbounded goroutines from request input.
- Bound retries and use backoff/circuit breakers for Mapbox, Redis, RabbitMQ, and downstream calls. Ensure retries cannot repeat non-idempotent effects.
- Handle context cancellation and close response bodies, database rows, Redis/pubsub resources, files, and WebSocket connections.

## Review output

Report only evidence-backed findings using this shape:

```text
### [High] Short vulnerability title
Location: path/to/file.go:line
Data flow: attacker-controlled source -> validation/guard -> sensitive sink
DREAD: Damage=x, Reproducibility=x, Exploitability=x, Affected=x, Discoverability=x; total=x
Impact: concrete security consequence for this service or user role
Existing defenses: relevant middleware, parser, authorization, or deployment control
Fix: smallest complete remediation and required regression coverage
Verification: commands run and exact result; do not claim checks that did not run
```

For coding work, keep changes focused and add tests for both the allowed and rejected paths. For audit work, separate findings from suggestions and do not silently fix unrelated quality issues.

## Verification

Run the narrowest relevant checks first, then expand:

```bash
GOCACHE=/tmp/driveapp-go-cache go test ./...
GOCACHE=/tmp/driveapp-go-cache go test -race ./...
go vet ./...
```

When installed, run `govulncheck ./...` and `gosec ./...`. If a tool is missing or network access is unavailable, report that limitation instead of installing dependencies or claiming a scan passed. Finish with `git diff --check` and inspect the final diff for secrets, broad route exposure, and accidental changes to unrelated services.
