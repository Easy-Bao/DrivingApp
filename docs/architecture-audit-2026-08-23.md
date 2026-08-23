# Comprehensive Full-Stack Architecture, API, & Database Performance Audit

Date: 2026-08-23

Scope: passenger and driver clients, the service layer, HTTP contracts, persistence migrations, location providers, and the current test/tooling boundary.

## 1. Executive Summary & Critical Vulnerabilities

### Resolved high-impact findings

1. **Ride economics could drift across assignment and settlement.** Accepted offers now freeze the fare and derive commission and driver payout from the same centavo-valued snapshot. The server rejects inconsistent monetary inputs instead of silently accepting client-calculated totals.
2. **Schema evolution was coupled to startup and unsafe for existing data.** Migration execution now has an ordered ledger, an advisory lock, compatibility checks, additive schema synchronization, explicit backfills, relational integrity, and a bounded migration timeout. Existing databases still require a staged deployment rehearsal; a fresh database passing is not evidence that every legacy null/value shape is safe.
3. **Authorization was too dependent on transport-level identity.** Role-aware principals and ride-scoped counterparty checks now sit between authentication and feature use cases. Passenger and driver code cannot select arbitrary ride participants by supplying another user ID.
4. **High-frequency or sensitive routes lacked workload-specific controls.** Idempotency and rate limiting are applied to mutation classes, while telemetry and internal streams are not treated like ordinary public mutations. Proxy trust is explicit rather than inferred from arbitrary forwarded headers.
5. **Client presentation layers constructed transport details.** Concrete remote data sources, ad-hoc HTTP clients, and chat socket construction were moved behind feature-owned repository ports and composition-root factories. Shared contracts are typed snapshots/DTOs, not a shared domain implementation for both apps.
6. **Reporting and proximity endpoints over-fetched or performed repeated work.** History/stats reads are paged or bounded, response DTOs are lean, and candidate distance selection uses one bounded matrix lookup rather than one provider request per candidate.

### Remaining risks, ordered by impact

- **High:** Run the migration suite against a copy of the oldest supported production schema and representative dirty rows. A migration that adds a non-null timestamp can fail before a backfill if it is introduced in the wrong order; this is the class of failure seen during local startup and is now covered by the explicit migration boundary, but needs an old-schema rehearsal.
- **Medium:** Capture `EXPLAIN (ANALYZE, BUFFERS)` for ride history, active ride lookup, open bid sessions, wallet ledger, and notification feeds in a production-like dataset. The required indexes exist in code, but planner behavior and index selectivity are runtime facts.
- **Medium:** Finish removing service-locator lookups from remaining presentation entry points. The high-value repository/data-source leaks are gone, but a few screen composition paths still obtain blocs/services through the navigation container.
- **Low:** Continue decomposing the largest remaining screens. The expensive feed/search rules and dashboard cards have been extracted; the residual files still contain lifecycle orchestration and can be split further without introducing another generic UI framework.

## 2. Architecture & File Structure Refactoring Plan

### Boundaries implemented

- Server responsibilities are separated as transport DTO/handler, use case, domain port, and adapter. HTTP handlers validate and map errors; use cases own business rules; adapters own provider/database details.
- Driver and passenger clients own their repositories and feature DTOs. The shared package contains only genuinely cross-app primitives such as typed ride snapshots, counterparty identity, authentication/session contracts, and common presentation foundations.
- Chat repository construction is owned by the composition root. Feature pages consume an interface/factory and no longer create `Dio`, WebSocket transport, or token plumbing themselves.
- Dashboard feed cards/countdown presentation and destination search formatting/sorting/distance rules were extracted from their page monoliths. These seams are independently testable and do not force a cross-app UI dependency.
- Unreachable duplicate barrels, abandoned route optimization code, duplicate fare/ride repository stacks, and unused client scaffolding were removed after reference checks.

### Naming and extraction recommendations

| Area | Finding | Boundary |
| --- | --- | --- |
| Dashboard pages | Page files still coordinate lifecycle, state, and layout after the feed extraction | Extract state-to-view models and section widgets; keep repository orchestration in the page/controller boundary |
| Destination search | Pure matching/sorting/distance rules are isolated; the screen still owns map/search lifecycle | Extract search state/controller from map selection and result rendering |
| Navigation shell | Driver and passenger floating tab bars are app-specific, not a shared domain widget | Keep independent implementations; share only theme tokens and animation constants through AppThemes |
| Location | Matrix is a location use case, not a generic utility | Keep validation/cache/provider conversion in the location feature; do not move it into a global helper |
| Documents | Metadata and private object access have different lifecycles | Keep metadata in the driver-document feature and object storage behind a private storage port |

### Middleware placement

Authentication and role guards belong at route boundaries. Ride ownership/counterparty authorization belongs in the ride use case because it must also protect non-HTTP callers. Rate limiting belongs at public mutation and expensive provider boundaries, with separate budgets for login, booking, chat setup, location matrix, and telemetry. Do not put a single global limiter around internal high-throughput streams or use a forwarded client IP unless the proxy trust boundary is configured.

The remaining simplification target is service-locator usage in screen composition. Replace each remaining lookup with constructor injection at the route/module boundary; do not add another global abstraction layer.

## 3. API Contract & Latency Diagnostics

### Contract and type issues addressed

- Fare values are represented as integer centavos at the server boundary and converted to display currency only in presentation. This removes float/string ambiguity between client history, active rides, settlements, and driver earnings.
- Request DTOs reject missing IDs, invalid coordinates, invalid enum/status values, and out-of-range pagination instead of allowing silent zero values or nullable transport fields to reach use cases.
- Error responses use a consistent problem shape with actionable status/message data. Authorization failures are not represented as successful empty payloads.
- Ride history, dashboard counts, driver statistics, and nearby-driver responses use purpose-built DTOs with bounded pages/limits rather than serializing database entities and unrelated profile fields.
- Client repositories normalize server identifiers and response nullability at the data boundary. Presentation widgets consume stable domain values instead of raw JSON maps.

### Latency drivers and current treatment

- **Repeated routing calls:** candidate selection now calls one bounded matrix operation and caches the result by normalized coordinates. The provider adapter converts meters/seconds to the app’s distance/time units once. The endpoint remains capped because the Mapbox Matrix API is an expensive external dependency: [Mapbox Matrix API](https://docs.mapbox.com/api/navigation/matrix/).
- **Serial independent reads:** profile, ride, and related counterparty reads that have no dependency should be issued concurrently in the use case; dependent authorization and mutation steps remain sequential and transactional.
- **Telemetry churn:** location updates are isolated from ride mutation paths and should not make the user-facing online transition fail after the durable state is committed. Cleanup failures are observable separately from the primary transition.
- **Side effects:** notifications, realtime publication, and telemetry fan-out must remain after the core transaction or in a worker/queue boundary. They must not determine whether a successful booking or trip transition is returned as a 5xx.
- **Timeouts:** external provider and database operations receive request contexts. The migration runner has its own bounded timeout so startup cannot wait indefinitely on a lock or long backfill.

### Required production measurements

Record request duration, database duration, provider duration, result count, and cache hit/miss using low-cardinality route labels. Then validate the following with representative data: p95 active-ride lookup, p95 history page, matrix provider p95, database pool wait time, and rate-limit rejection rate. Avoid logging tokens, private document URLs, message bodies, or precise location payloads.

## 4. Database Schema Optimization & Decomposition Plan

### Current schema assessment

The ride table is a hot operational record with passenger/driver IDs, lifecycle status, coordinates/names, fare, payment, commission, payout, and display snapshots. This is serviceable for the current scale, but it mixes three lifecycles:

1. core ride state and route identity;
2. mutable financial settlement state;
3. denormalized display/provider snapshots.

The financial satellite (`ride_settlements`) and wallet ledger now provide a better ownership boundary. Foreign keys, partial uniqueness for active rides/open bid sessions, and history/reporting indexes are explicit. Monetary columns use integer centavos; commission rates use basis points.

### Recommended vertical partitioning

Keep in `rides`: `id`, passenger/driver IDs, lifecycle status, pickup/drop-off coordinates and names, ride type, `created_at`, and `completed_at`.

Keep in `ride_settlements`: `ride_id`, gross fare, commission basis points, commission amount, driver payout, payment status, cash timestamp, settlement timestamp, and update/version metadata. Treat this table as the only mutable source for post-assignment financial state.

Move to a route/provider snapshot table when growth justifies it: distance, duration, provider route revision, and user-facing driver/vehicle snapshot fields. These values are useful for historical display but should not enlarge the hottest ride status row indefinitely.

Keep high-frequency driver location in a separate current-location table or ephemeral location store keyed by driver ID. Do not add location updates to `rides`; that would create write amplification and MVCC churn on a read-heavy lifecycle row. Retain a separately governed history stream only if product or compliance requires it.

Keep chat messages, audit events, and document metadata outside the ride row. Large/private blobs must remain in private object storage with database metadata and authorization checks.

### Index and migration rules

- Preserve indexes for `(passenger_id, created_at)`, `(driver_id, created_at)`, status/completion reporting, open bid expiry, session/offer access, and ledger history.
- Index every foreign-key access path that is used for lookup or deletion; do not blindly index every column.
- Prefer partial unique indexes for one active ride per passenger and one open bid session per passenger.
- Backfill before enforcing `NOT NULL`; deploy additive columns before code reads them; validate foreign keys after cleanup; record every step in the migration ledger.
- Rehearse migrations with old rows and concurrent startup processes. The advisory lock prevents concurrent runners but does not make an unsafe statement safe.

### Illustrative target DDL

```sql
CREATE TABLE ride_settlements (
    ride_id BIGINT PRIMARY KEY REFERENCES rides(id) ON DELETE RESTRICT,
    gross_fare_centavos BIGINT NOT NULL CHECK (gross_fare_centavos >= 0),
    commission_bps BIGINT CHECK (commission_bps BETWEEN 0 AND 10000),
    commission_centavos BIGINT NOT NULL DEFAULT 0 CHECK (commission_centavos >= 0),
    driver_payout_centavos BIGINT NOT NULL DEFAULT 0 CHECK (driver_payout_centavos >= 0),
    payment_status TEXT NOT NULL,
    cash_received_at TIMESTAMPTZ,
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ride_passenger_history_idx ON rides (passenger_id, created_at DESC);
CREATE INDEX ride_driver_history_idx ON rides (driver_id, created_at DESC);
CREATE UNIQUE INDEX ride_one_active_passenger_idx ON rides (passenger_id)
WHERE status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit');
```

This DDL is a target shape, not an instruction to run an ad-hoc production migration. The ordered migration runner remains the deployment mechanism.

## 5. Refactored Code Implementation

The implementation is distributed across the commits for this audit rather than hidden in this document:

- `08b4361e` freezes accepted-offer economics and validates centavo invariants.
- `fba91a84` introduces ordered schema evolution, compatibility checks, backfills, constraints, and indexes.
- `1c618783` enforces role-bound principals and strict request/problem contracts.
- `79075883` scopes counterparty, chat, and telemetry access to the ride.
- `b3cfec91` separates rate limits, idempotency, proxy trust, and database pooling by workload.
- `e8806fcc` bounds history/stats/proximity work and adds matrix-based selection.
- `2fd43fc6` makes driver documents immutable/private at the application boundary.
- `f24cc679` through `ec93947e` isolate client feature ports, remove duplicate scaffolding, and extract high-value dashboard/search boundaries.

Representative clean boundary:

```go
type RideRepository interface {
    FindByID(ctx context.Context, rideID int) (RideSnapshot, error)
    FindCounterparty(ctx context.Context, rideID int, principal Principal) (Counterparty, error)
}

func (service *Service) StartTrip(ctx context.Context, principal Principal, rideID int) error {
    ride, err := service.rides.FindByID(ctx, rideID)
    if err != nil {
        return err
    }
    if err := ride.AuthorizeDriver(principal); err != nil {
        return err
    }
    return service.rides.Start(ctx, rideID)
}
```

The handler maps HTTP input to this use case; it does not query unrelated profiles, construct a provider client, or decide who may operate the ride. The client presentation layer follows the same rule: it renders typed feature state and does not construct transport objects.

### Refactoring action plan

1. Run old-schema migration rehearsal and capture rollback/forward timings.
2. Capture production-like query plans and remove only indexes proven redundant.
3. Move remaining screen-level service-locator lookups to route composition.
4. Split residual dashboard/search lifecycle code into feature controllers and view sections.
5. Add contract tests that execute the client DTO fixtures against the server problem/response envelopes.
6. Add metrics dashboards for pool wait, provider latency, idempotency replay, matrix cache hit rate, and side-effect failures.
