# EasyRide Admin MVP operations guide

Last reviewed: 2026-08-01

## Scope and architecture

The EasyRide private operations portal is an online, server-rendered SvelteKit
application. It is desktop-first, remains usable on a tablet, and is not a
native desktop application.

The frontend lives in `web/admin_app`; Passenger and Driver mobile clients
remain under `Apps/`.

The browser talks only to SvelteKit. SvelteKit calls the API gateway from its
server-side loads and form actions, so the eight-hour admin JWT stays in the
legacy-named `baobao_admin_session` HttpOnly, SameSite=Strict cookie and is
never exposed to browser JavaScript. Use HTTPS in every non-local environment
so the cookie is Secure. Renaming the internal cookie belongs in the future
EasyRide branding change and will sign out existing sessions.

```text
Owner browser
  -> SvelteKit admin app
    -> API gateway
      -> auth-service
      -> admin-service
        -> driver, passenger, trip, bidding, and fare services
          -> PostgreSQL
```

The gateway exposes `/admin/*` to the dashboard and removes any client-supplied
internal-service headers. Service-to-service requests use
`INTERNAL_SERVICE_TOKEN` only on the trusted backend network. The dashboard
polls operational views every 10 seconds; this MVP does not add another
WebSocket service.

The owner can use:

- Overview, driver approval, and document verification.
- Live requests, active trips, the Mapbox dispatch map, and manual assignment.
- Driver prepaid balances, top-up channels and reviews, fares, and commission
  policy.
- Pagadian barangay service zones.
- Complaints, temporary or indefinite restrictions, and restriction lifting.
- Filtered CSV reports, printable report views, and the append-only audit log.

Manual assignment cannot bypass driver approval, document, restriction, zone,
fare-snapshot, or available-credit checks.

## Current implementation status

This is not a from-scratch project. A broad prototype exists across the Admin
frontend, Admin backend, authentication, gateway, Driver, Passenger, Trip,
Bidding, Fare, Docker, database migrations, and limited mobile integration.
`repo-current-state.md` records the latest branch, runtime, and verification
facts.

| Module | Current status |
|---|---|
| Owner access and security | Implemented; disposable-stack login and protected SvelteKit report session passed |
| Overview and operational queues | Implemented; authoritative source totals and pagination checks passed |
| Driver applications | Missing |
| Drivers and compliance | Partial; approval and generic document metadata exist, but private evidence intake and complete identity review do not |
| Passengers and vehicles | Missing as searchable Admin records |
| Trips and dispatch | Partial; live data and manual assignment exist on the old bidding contract |
| Driver prepaid balance and top-ups | Current success, retry, cancellation-release, and reconciliation paths passed with synthetic money |
| Fare and commission | Partial; current formula conflicts with the latest first/succeeding-kilometer direction |
| Service zones | Implemented for development data; official public boundary approval remains open |
| Cases and restrictions | Basic workflow implemented; categories, escalation, and appeals remain open |
| Reports and audit | Pagination and controlled source reconciliation passed; visual Print / Save as PDF review remains |

Focused Admin, auth, gateway, Driver, Passenger, Trip, Bidding, Fare, location,
and Flutter tests cover the current invariants. A disposable current-prototype
orchestration also passed; the final mobile and product contracts have not.

## Initial implementation plan and present position

The original delivery plan used three additive slices:

1. **Foundation:** owner authentication, security middleware, reviewed
   migrations, gateway routing, and Docker/service wiring.
2. **Core operations:** driver compliance, prepaid balance and top-ups, service
   zones, restrictions, fare and commission snapshots, and safe assignment and
   settlement.
3. **Operations portal and acceptance:** SvelteKit screens, required mobile
   integration, reports, tests, runbooks, and a complete end-to-end ride.

The first implementation combined much of all three into one broad prototype
rather than three reviewable pull requests. Do not restart it. Treat the current
position as **prototype stabilization and contract alignment**:

- Foundation code passed clean disposable-stack login, migration, seed, and
  gateway verification.
- Core operations are broadly present, but matching, fare, Shared, Premium,
  cancellation, and some idempotency/reporting contracts do not match or do not
  yet prove the latest product direction.
- The portal is usable as a prototype and its protected report path passed.
  Complete record-management screens, final mobile integration, authenticated
  visual workflow acceptance, and production readiness remain.

Continue from here with one small, testable issue and one coherent pull request
at a time. Preserve the existing prototype and replace or extend only the
contract slice covered by the active issue.

## Cross-service contract

The Admin portal does not communicate directly with the Passenger or Driver
apps. All three surfaces use the same gateway and backend records:

```text
Passenger and Driver apps -> API gateway -> shared backend services
Admin browser -> SvelteKit -> API gateway -> admin-service -> shared backend services
```

Shared contracts must use the same authenticated identities, IDs, status
values, fare snapshots, error codes, UTC timestamps, and idempotency rules.
Admin mutations cannot make a driver eligible when the Driver or Trip backend
would reject the same operation.

### Matching and dispatch

The confirmed product direction is:

- The platform calculates a fixed fare; drivers do not propose prices.
- The passenger sees five nearest eligible drivers ordered by pickup
  distance/road ETA, refreshes the list every five seconds, and selects one.
- The driver sees requests oldest first and accepts or declines.
- The first atomic acceptance wins.
- Premium acceptance removes that vehicle from availability for the trip.
- A Shared vehicle may remain discoverable only under the still-open compatible
  capacity and route rules.

The current code instead uses driver offers followed by passenger acceptance.
Admin manual assignment creates or selects an offer through the same older
bidding path. Atomic claim and rollback protection exist, but they do not prove
the confirmed matching model. Do not describe the target flow as implemented
until its backend and both mobile clients pass concurrency and end-to-end tests.

### Fare and ride products

The current product direction excludes a time charge:

```text
routeFare = firstKilometerAmount
  + succeedingKilometerRate * max(0, distanceKilometers - 1)
```

Exact amounts, rounding, minimum fare, distance source, and surge policy remain
open. The existing Fare service still uses base fare plus all distance, time,
minimum, and surge fields, so it requires a separate contract-alignment change.

Shared uses a `1.0` MVP multiplier with no occupancy-dependent or retroactive
discount. Unrelated passengers may use different pickup and destination stops,
but seat-per-booking, detour, wait, sequencing, and post-acceptance
discoverability rules remain open.

Premium is exclusive to one booking party with predeclared immutable
destinations and no in-app fare split. Its allowed party model and price remain
open; do not implement a single-passenger, additional-passenger, or
vehicle-wide model as final without a confirmed decision.

### Cancellation and interruption

A Shared cancellation before pickup removes only that passenger's pickup and
destination, keeps other quoted fares unchanged, and releases only that
booking's commission reservation. Voluntary early drop-off retains the quoted
fare. General cancellation fees, no-show rules, driver consequences, and unpaid
cash settlement remain open.

When the driver causes an incomplete trip, charge the passenger nothing,
release the commission reservation, and create an interrupted-trip Admin case.
Any driver compensation is reviewed separately.

## Configuration and secret handling

Keep actual values in the deployment secret store or an untracked `.env` file.
The repository contains only environment-variable names and safe local
defaults. Never commit an owner password, JWT, database credential, internal
token, e-wallet password or PIN, or secret Mapbox token.

### Database and shared security

| Name | Source | Use |
|---|---|---|
| `POSTGRES_USER` | Deployment configuration | Local/Compose PostgreSQL role |
| `POSTGRES_PASSWORD` | Secret store | Local/Compose PostgreSQL credential |
| `POSTGRES_DB` | Deployment configuration | Local/Compose database name |
| `DATABASE_URL` | Secret store | Database connection used by each service |
| `AUTH_DB_URL` | Secret store | Optional dedicated auth database |
| `PASSENGER_DB_URL` | Secret store | Passenger identity database used by auth |
| `DRIVER_DB_URL` | Secret store | Driver identity database used by auth |
| `JWT_SECRET` | Shared backend secret | JWT signing and verification secret |
| `INTERNAL_SERVICE_TOKEN` | Shared backend secret | Backend-only service authentication |

`JWT_SECRET` must match in auth and every JWT-verifying service.
`INTERNAL_SERVICE_TOKEN` must match in admin, driver, passenger, trip, bidding,
fare, telemetry, and chat services that use internal routes.

### Service discovery and runtime

| Name | Source | Use |
|---|---|---|
| `AUTH_SERVICE_URL` | Deployment configuration | Gateway route to auth-service |
| `PASSENGER_SERVICE_URL` | Deployment configuration | Gateway and backend passenger-service route |
| `DRIVER_SERVICE_URL` | Deployment configuration | Gateway and backend driver-service route |
| `TRIP_SERVICE_URL` | Deployment configuration | Gateway and backend trip-service route |
| `BIDDING_SERVICE_URL` | Deployment configuration | Gateway and backend bidding-service route |
| `TELEMETRY_SERVICE_URL` | Deployment configuration | Gateway route to telemetry-service |
| `CHAT_SERVICE_URL` | Deployment configuration | Gateway route to chat-service |
| `FARE_SERVICE_URL` | Deployment configuration | Gateway and backend fare-service route |
| `ADMIN_SERVICE_URL` | Deployment configuration | Gateway and backend admin-service route |
| `GATEWAY_URL` | Deployment configuration | Server-only gateway URL used by SvelteKit |
| `PORT` | Process configuration | Per-process listening port |
| `HOST` | Process configuration | Admin-app listening interface |
| `SESSION_TTL_MINUTES` | Backend configuration | Bidding-session lifetime |

Service URLs are routing configuration, not passwords. They may be shared in
normal team documentation unless the host topology itself is confidential.
Internal services should not be publicly reachable merely because their URLs
are non-secret.

The untracked `.env` service URLs are for processes launched directly on the
host. Docker Compose deliberately uses Compose service names such as
`http://passenger-service:8081`; `127.0.0.1` inside a container refers only to
that container and must not be used for container-to-container routing.

### Email and web deployment

| Name | Source | Use |
|---|---|---|
| `SMTP_HOST` | Email-provider configuration | Authentication email server |
| `SMTP_PORT` | Email-provider configuration | Authentication email server port |
| `SMTP_USER` | Secret store | Authentication email identity |
| `SMTP_PASS` | Secret store | Authentication email credential |
| `SMTP_FROM` | Deployment configuration | Sender identity |
| `PUBLIC_MAPBOX_TOKEN` | Mapbox configuration | Public browser token for the dispatch map |
| `ORIGIN` | Deployment configuration | Public HTTPS origin expected by SvelteKit |
| `ADMIN_APP_ORIGIN` | Deployment configuration | Compose input for the public Admin origin |

Only a public, URL-restricted Mapbox token may reach the web or Flutter clients.
Rotate any secret Mapbox token that was previously shared or bundled.

Top-up destination account name, public account reference, and driver
instructions are runtime records configured by the owner. They are not
environment secrets. E-wallet passwords, PINs, recovery codes, and private
payment API credentials must never be stored.

`RUN_DRIVER_OPERATIONS_INTEGRATION` is test-only and must point only to a
disposable migrated database when enabled.

## Local startup

Prerequisites are Git, Bun, and either PostgreSQL plus `psql`, or Docker
Desktop. A public Mapbox token is needed to render the dispatch map; the other
dashboard sections can be developed without the map.

1. Copy the root `.env.example` to an untracked `.env` and populate the required
   values through the team's approved secret-sharing process.
2. Install dependencies in each backend service that will be run and in
   `web/admin_app`.
3. Start PostgreSQL.
4. Back up the target database, review and apply the additive migrations in
   the order below, then seed admin configuration.
5. Provision the private owner.
6. Start auth, passenger, driver, trip, bidding, fare, admin, and gateway
   services. Start telemetry and chat when testing those existing features.
7. Start `web/admin_app` with `bun run dev`.
8. Open `http://localhost:5173`.

In each Bun project, dependency installation and development startup are:

```sh
bun install
bun run dev
```

When services are started directly, the usual local health URLs are the gateway
at `http://localhost:8080`, auth at `http://localhost:8088`, and admin-service
at `http://localhost:8089`. The current Compose file publishes only PostgreSQL
`5432`, the gateway `8080`, and the Admin app `5173`; the backend ports remain
inside the Compose network. A health response proves only that a process is
listening, so complete the acceptance checks before treating the system as
ready.

## Reviewed additive migrations

Never run `db:push` against shared staging or production. It bypasses the
reviewed migration history and may make destructive schema changes.

Before every shared-environment migration:

1. Take and verify a restorable backup or point-in-time recovery marker.
2. Stop or drain state-changing traffic.
3. Review the exact SQL against the current database schema.
4. Apply each file once with stop-on-error and a transaction where PostgreSQL
   permits it.
5. Verify constraints, indexes, row counts, and old-client compatibility before
   continuing.
6. Record the applied file and checksum in the deployment migration registry.

Apply the current admin-MVP migration groups in this order. Run each group
against the `DATABASE_URL` for the service that owns its tables; a deployment
that deliberately shares one database still applies the files in the same
order.

| Order | Service schema | Reviewed files |
|---|---|---|
| 1 | auth-service | `server/auth-service/migrations/0001_admin_auth_accounts.sql` |
| 2 | driver-service | `server/driver-service/drizzle/0000_driver_operations.sql`, then `0001_driver_email_verification.sql` |
| 3 | passenger-service | `server/passenger-service/drizzle/0000_gigantic_klaw.sql` |
| 4 | admin-service | `server/admin-service/drizzle/0000_legal_sister_grimm.sql`, then `0001_colorful_mister_fear.sql` |
| 5 | fare-service | `server/fare-service/drizzle/0000_wandering_sharon_carter.sql`, then `0001_ambiguous_mac_gargan.sql`, then `0002_legacy_upgrade.sql` |
| 6 | trip-service | `server/trip-service/drizzle/0000_fast_grim_reaper.sql`, then `0001_true_husk.sql`, then `0002_daily_retro_girl.sql`, then `0003_legacy_upgrade.sql` |
| 7 | bidding-service | `server/bidding-service/drizzle/0000_amusing_wildside.sql`, then `0001_handy_sunspot.sql` |

Some `0000` files describe a fresh service schema using `CREATE TABLE IF NOT
EXISTS`. That does not add newly described columns to a table that already
exists. Before upgrading an existing staging database, require and review an
explicit additive `ALTER TABLE` migration for every schema difference. Do not
infer that a fresh-schema migration upgraded an existing table.

One way to apply a reviewed SQL file from PowerShell is:

```powershell
psql $env:DATABASE_URL --set ON_ERROR_STOP=1 --single-transaction --file <reviewed-migration.sql>
```

After the admin migrations, seed the official roster, interim geometry, and
initial commission policy:

```sh
cd server/admin-service
bun run db:seed
```

### Rollback policy

Prefer application rollback over destructive schema rollback because the
changes are additive:

1. Stop writes and save logs, request IDs, and the failed migration output.
2. Roll application images back to the last compatible version.
3. Leave compatible nullable columns and new tables in place.
4. If data restoration is necessary, restore the pre-migration backup into a
   separate database and verify it before switching traffic.
5. Never drop or rewrite the driver credit ledger, credit reservations, top-up
   history, fare transactions, mutation results, or audit events as a routine
   rollback.

Zone activation can be rolled back by deactivating the affected barangays.
Do not delete the roster or audit history.

## Docker startup

Docker Compose is intended for local development and can be adapted to the
deployment host.

```sh
docker compose config
docker compose up -d postgres-db
```

On a new PostgreSQL volume,
`server/database/init/001-create-service-databases.sql` creates the auth,
passenger, driver, trip, bidding, chat, fare, and admin databases. Fare uses
its dedicated `fare_db`; every service must receive the matching migrated
database URL.

All `*_DATABASE_URL_DOCKER` values must resolve the database host as
`postgres-db` from inside Compose. Some existing local values and already
running containers still use the former `passenger-db` service name. Before a
rebuild, back up the database, inspect `docker compose config` and
`docker compose ps -a`, and deliberately reconcile any legacy/orphan container.
Do not use `docker compose down -v` because it deletes the PostgreSQL volume.

Apply the reviewed migrations from the checked-out source, seed admin-service,
and provision the owner before opening the dashboard. Then build and start the
stack:

```sh
docker compose up --build -d
docker compose ps
```

Provisioning can run in an interactive one-off auth container:

```sh
docker compose run --rm auth-service bun run owner:provision
```

Do not declare the Docker deployment ready until every referenced Dockerfile
builds, all migration and seed commands finish, `docker compose ps` is healthy,
the gateway can reach every configured service URL, and the end-to-end
acceptance flow passes.

For a public deployment, terminate TLS at the deployment reverse proxy, send
the private portal domain to the `admin-app` runtime, keep service ports on a
private network, and set the SvelteKit origin to the exact HTTPS URL. The public
S3/CloudFront website is a separate surface and does not replace this
server-rendered authenticated portal.

## Owner provisioning and rotation

There is one privately provisioned owner and no public admin registration,
email reset, or default password.

After the auth migration, run this from an interactive terminal:

```sh
cd server/auth-service
bun run owner:provision
```

The command asks for the owner email and a 12-to-128-character password without
echoing the password. The first run creates the owner. Running it again with
the same normalized email rotates the password and clears the login lock.
Running it with a different email refuses to replace the existing owner, which
prevents accidental second-owner creation.

Share the initial password once through an approved password manager, then let
the owner rotate it. Never put it in chat, source code, an issue, an API example,
or `.env`. Five failed logins cause a persistent 15-minute lock. Signing out of
the dashboard removes the local session cookie.

## Driver prepaid-balance rules

The current database and API use `credit` in several technical names. In
driver-facing and planning language, call this the **driver prepaid balance**:
money the driver deposits so the system can reserve the platform commission.

- Store and transmit money as integer centavos.
- Store rates as basis points. The initial `1,000` basis-point rate is 10%.
- The minimum top-up is 10,000 centavos (₱100).
- The credited wallet balance may not exceed 100,000 centavos (₱1,000).
- A driver may sign in and inspect history while blocked. Ride acceptance is
  blocked whenever the available prepaid balance cannot cover that ride's exact
  commission.
- Assignment snapshots the fare, commission rate, commission amount, and
  assignment source. Later pricing changes are not retroactive.
- Assignment reserves the exact commission. Completion settles it,
  cancellation releases it, and reported unpaid cash changes it to disputed so
  the money remains held for owner review.
- Wallet and reservation transactions prevent negative balances. Mutations
  require idempotency keys so retries do not double-credit or double-charge.
- After the first real ride, a later commission change requires at least 30
  days' notice.

## Top-up operations

### Configure a channel

The owner creates an active channel containing only its public display name,
destination account name/reference, and payment instructions. Confirm that the
destination belongs to EasyRide and that the person reviewing payments can see
the receiving account independently.

### Verify or reject a request

1. The driver chooses an active channel and sends money outside the app.
2. The driver submits the channel, amount, sender name, and transaction
   reference. No screenshot is collected.
3. The system normalizes references and rejects a duplicate reference for the
   same channel.
4. The owner compares the pending request with the receiving account's amount,
   sender, reference, and settlement status.
5. Approve only a settled, exact match. Use one new idempotency key and record a
   useful reason. Approval credits the immutable ledger exactly once.
6. Reject missing, reversed, mismatched, suspicious, or already-used payments
   and record the reason. Rejection never credits the wallet.
7. Never “fix” a review by editing database rows. Use an audited credit
   adjustment only after reconciliation.

Concurrent submissions are safe to queue. Database locks, unique normalized
references, and idempotency records protect the balance; one owner may review
five simultaneous requests sequentially without corrupting money. The
operational delay is visible as `pending`.

### Duplicate or retried review

- Reusing the same idempotency key with the same operation returns the saved
  result.
- Reusing it for another operation is rejected.
- A second decision on an already-reviewed top-up is rejected.
- If the external wallet and ledger disagree, stop approvals, retain the
  request and transaction references, and reconcile before any adjustment.

Current limitation: Admin mutation results are keyed by the idempotency key and
operation name, but do not yet bind the key to a request-target and payload
fingerprint. Until that is corrected and concurrency-tested, never intentionally
reuse an idempotency key for a different target or body.

### Verified account-closure refund

Paid, unused credits are refundable only during verified account closure:

1. Verify the driver's identity and closure request through the team's approved
   support procedure.
2. Restrict new ride activity and confirm there are no active rides, pending
   status transitions, unresolved disputed reservations, or pending top-ups.
3. Reconcile the immutable ledger and identify only paid, unused credit.
4. Confirm the external refund destination with the driver.
5. Send the refund outside the app, retain the external transfer reference, and
   record the matching audited credit-refund operation with a clear reason.
6. Confirm that wallet, ledger, top-ups, reservations, and external payment
   records reconcile before closing the account.

Do not refund promotional or already-consumed credit, and do not delete the
account's financial history.

## Pagadian service zones

`bun run db:seed` loads the current 54-name
[PSA Pagadian barangay roster](https://psa.gov.ph/classification/psgc/barangays/0907322000).
Every barangay starts inactive. The team chooses the pilot barangays at runtime;
the implementation does not guess them.

The included development geometry is extracted from
[UN OCHA HDX Philippines administrative boundaries](https://data.humdata.org/dataset/cod-ab-phl)
and is attributed as interim data under its recorded source license. Activating
a zone requires geometry. Both pickup and destination must fall inside active
barangays; polygon boundary points count as inside.

HDX geometry is a development aid, not the public launch authority. Before
public enforcement, obtain Pagadian LGU/NAMRIA verification or written approval
to use the current boundary data, record the approved source/version, test
boundary points, and only then activate the chosen pilot barangays.

## Pending trip reconciliation

Ride status changes durably record a pending transition before downstream
credit and fare updates. If a service or database failure interrupts that saga,
call the reconciliation endpoint before making any manual wallet adjustment:

```sh
curl --request POST "$TRIP_SERVICE_URL/rides/internal/reconcile" \
  --header "X-Internal-Service-Token: $INTERNAL_SERVICE_TOKEN"
```

Call this directly from the trusted backend network. Do not send it through the
public gateway because the gateway deliberately strips internal credentials.
The response reports each pending ride as succeeded or failed and includes a
UTC `reconciled_at` timestamp. Preserve failed ride IDs and request IDs, restore
the unavailable dependency, and retry. Never settle, release, or dispute a
reservation by editing its rows.

## API examples

These examples contain placeholders only. Admin requests normally go through
the gateway. State-changing admin requests require the admin bearer token, a
unique `Idempotency-Key`, and a reason where the schema requires one.

Sign in:

```sh
curl --request POST "$GATEWAY_URL/auth/admin/login" \
  --header "Content-Type: application/json" \
  --data '{"email":"<owner-email>","password":"<owner-password>"}'
```

List pending drivers:

```sh
curl "$GATEWAY_URL/admin/v1/drivers?status=pending&page=1&limit=25" \
  --header "Authorization: Bearer $ADMIN_JWT"
```

Approve a driver:

```sh
curl --request POST "$GATEWAY_URL/admin/v1/drivers/<driver-id>/approval" \
  --header "Authorization: Bearer $ADMIN_JWT" \
  --header "Idempotency-Key: <unique-request-id>" \
  --header "Content-Type: application/json" \
  --data '{"status":"approved","reason":"Identity and required documents verified"}'
```

Review a top-up:

```sh
curl --request POST "$GATEWAY_URL/admin/v1/topups/<top-up-id>/review" \
  --header "Authorization: Bearer $ADMIN_JWT" \
  --header "Idempotency-Key: <unique-request-id>" \
  --header "Content-Type: application/json" \
  --data '{"status":"approved","reason":"Matched settled receiving-account transaction"}'
```

Activate a reviewed zone:

```sh
curl --request PUT "$GATEWAY_URL/admin/v1/zones/<psgc-code>" \
  --header "Authorization: Bearer $ADMIN_JWT" \
  --header "Idempotency-Key: <unique-request-id>" \
  --header "Content-Type: application/json" \
  --data '{"is_active":true,"reason":"Approved pilot barangay"}'
```

Download a filtered CSV:

```sh
curl "$GATEWAY_URL/admin/v1/reports/trips?from=<iso-utc>&to=<iso-utc>" \
  --header "Authorization: Bearer $ADMIN_JWT" \
  --header "Accept: text/csv"
```

The dashboard displays ISO-8601 UTC timestamps in Asia/Manila time. Supported
CSV report names are `trips`, `commissions`, `topups`, `compliance`, and
`cases`; printable dashboard routes use the browser's Print / Save as PDF.

## Deployment and launch gates

The deployment environment requires:

- A host that can run the SvelteKit Node adapter and Bun services.
- Dashboard DNS, HTTPS certificate, TLS termination, and reverse-proxy routing.
- Database URLs, database roles, backups, restore testing, and migration access.
- A matching `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN`, delivered securely.
- All service URLs and private network/service-discovery rules.
- A public, origin-restricted Mapbox token.
- SMTP configuration when passenger/driver email flows are in scope.
- The top-up destination's public account display information and a person
  authorized to verify incoming payments.
- The private owner email, initial credential procedure, and representative
  passenger/driver test accounts.
- Monitoring, logs, UTC clock synchronization, and an on-call/support contact.

The product team must decide:

- Which pilot barangays to activate.
- Whether the boundary authority has approved public enforcement.
- Document requirement names and expiry rules.
- Complaint categories, support wording, and restriction procedure.
- The real-ride launch date that starts the 30-day commission notice rule.

Public launch remains blocked until TLS, backups/restore, secret rotation,
boundary approval, pilot zones, top-up receiving-account controls, owner access,
test accounts, migrations, and the end-to-end acceptance flow are verified.

## Test and acceptance checklist

This is the required acceptance target, not a list of tests already completed.
Run these checks against a disposable migrated database and record the results;
never run destructive integration tests against staging or production.

- Auth: first owner creation, refusal of a different second owner, same-email
  rotation, successful login, invalid login, five-attempt lock, eight-hour
  expiry, logout, admin role enforcement, and non-admin rejection.
- Compliance: pending/approved/rejected drivers, incomplete and expired
  documents, active restrictions, expired restrictions, and backend rejection
  when the UI is bypassed.
- Zones: all-inactive startup, missing geometry, inside/outside points, polygon
  boundaries, and every pickup/destination combination.
- Money: exact centavo math at 10%, minimum/cap checks, low balance, duplicate
  references, concurrent submissions, repeated approvals, adjustments,
  verified refunds, immutable ledger protection, and full reconciliation.
- Rides: sufficient/insufficient credit, normal and manual assignment, fare and
  commission snapshots, retries, partial-service failure, cancellation release,
  completion settlement, unpaid-cash dispute, and reconciliation replay.
- Admin: every mutation writes actor, operation, target, reason/reference,
  before/after, outcome, request ID, and UTC timestamp without credentials or
  tokens; an idempotency key is bound to the target and payload as well as the
  operation; local mutation and audit persistence cannot silently separate.
- Compliance API: document requirement creation preserves expiry and active
  fields, requirements can be updated/deactivated safely, and private evidence
  access is authorized and audited.
- Reports: authoritative totals are independent of display-page limits; filters
  and pagination work; every CSV traverses the complete matching dataset and
  reconciles with source records; Manila display time and browser Print / Save
  as PDF output are correct.
- Dispatch contract: fixed-fare five-nearest selection, five-second refresh,
  manual-assignment reason propagation, and the same eligibility checks for
  normal and manual assignment.
- Driver finance: the Admin API exposes complete paginated ledger detail and
  every displayed balance reconciles with immutable entries and reservations.
- Frontend: Svelte checks, unit tests, production build, login cookie behavior,
  10-second refresh, tablet layout, Mapbox unavailable state, and owner workflow.
- Platform: service type checks/tests, migration tests, `docker compose config`,
  clean image builds, container health, private-service reachability, and a
  Docker smoke test.

Final acceptance is one traceable flow: provision the owner, approve a driver,
verify the required documents, activate selected barangays, approve a real
test top-up, normally or manually assign a ride, complete cash settlement,
handle a complaint/restriction, and export the resulting reports.

### 2026-08-01 disposable acceptance record

The `easyride-acceptance` Compose project used separate ports and its own
PostgreSQL volume. All fifteen services built and started; reviewed migrations
and Admin/Fare seeds completed. Synthetic identities then passed the current
offer-based owner → Driver → top-up → completed ride → settlement → case →
restriction → report flow. A second ride proved repeat acceptance and
cancellation are idempotent and release the reserved commission. Protected
SvelteKit CSV and print routes returned both the completed and canceled rides.

This is current-prototype software evidence, not public-launch acceptance. The
test used synthetic money, direct disposable-database identity verification,
development zone geometry, and no Android clients. Real payment verification,
safe SMTP/OTP testing, private document evidence, the final five-nearest
matching contract, final fare/Shared/Premium rules, visual print review, and
production infrastructure remain launch gates.

The isolated containers, network, and disposable PostgreSQL volume were removed
after the evidence was recorded. The normal local stack and its preserved
`ride-app_postgres_data` volume were not changed by that cleanup.

## Code and documentation convention

Backend work follows route → controller → service → repository, two-space
TypeScript formatting, single quotes, semicolons, and Zod validation. Use
selective `/** ... */` [JSDoc](https://jsdoc.app/about-getting-started) comments
for important exported operations and business invariants. Do not comment
obvious code and do not add a generated JSDoc website for this MVP.
