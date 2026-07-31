# BaoBao Admin MVP operations guide

## Scope and architecture

The BaoBao admin dashboard is an online SvelteKit application in
`apps/admin_app`. It is desktop-first and remains usable on a tablet. It is not
a native desktop application.

The browser talks only to SvelteKit. SvelteKit calls the API gateway from its
server-side loads and form actions, so the eight-hour admin JWT stays in the
`baobao_admin_session` HttpOnly, SameSite=Strict cookie and is never exposed to
browser JavaScript. Use HTTPS in every non-local environment so the cookie is
Secure.

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
- Service credits, top-up channels and reviews, fares, and commission policy.
- Pagadian barangay service zones.
- Complaints, temporary or indefinite restrictions, and restriction lifting.
- Filtered CSV reports, printable report views, and the append-only audit log.

Manual assignment cannot bypass driver approval, document, restriction, zone,
fare-snapshot, or available-credit checks.

## Configuration ownership

Keep actual values in the deployment secret store or an untracked `.env` file.
The repository contains only environment-variable names and safe local
defaults. Never commit an owner password, JWT, database credential, internal
token, e-wallet password or PIN, or secret Mapbox token.

### Database and shared security

| Name | Owner | Use |
|---|---|---|
| `POSTGRES_USER` | Infrastructure owner | Local/Compose PostgreSQL role |
| `POSTGRES_PASSWORD` | Infrastructure owner | Local/Compose PostgreSQL credential |
| `POSTGRES_DB` | Infrastructure owner | Local/Compose database name |
| `DATABASE_URL` | Database/infrastructure owner | Database connection used by each service |
| `AUTH_DB_URL` | Database/infrastructure owner | Optional dedicated auth database |
| `PASSENGER_DB_URL` | Database/infrastructure owner | Passenger identity database used by auth |
| `DRIVER_DB_URL` | Database/infrastructure owner | Driver identity database used by auth |
| `JWT_SECRET` | Backend security owner | Shared JWT signing and verification secret |
| `INTERNAL_SERVICE_TOKEN` | Backend security owner | Backend-only service authentication |

`JWT_SECRET` must match in auth and every JWT-verifying service.
`INTERNAL_SERVICE_TOKEN` must match in admin, driver, passenger, trip, bidding,
fare, telemetry, and chat services that use internal routes.

### Service discovery and runtime

| Name | Owner | Use |
|---|---|---|
| `AUTH_SERVICE_URL` | Deployment owner | Gateway route to auth-service |
| `PASSENGER_SERVICE_URL` | Deployment owner | Gateway and backend passenger-service route |
| `DRIVER_SERVICE_URL` | Deployment owner | Gateway and backend driver-service route |
| `TRIP_SERVICE_URL` | Deployment owner | Gateway and backend trip-service route |
| `BIDDING_SERVICE_URL` | Deployment owner | Gateway and backend bidding-service route |
| `TELEMETRY_SERVICE_URL` | Deployment owner | Gateway route to telemetry-service |
| `CHAT_SERVICE_URL` | Deployment owner | Gateway route to chat-service |
| `FARE_SERVICE_URL` | Deployment owner | Gateway and backend fare-service route |
| `ADMIN_SERVICE_URL` | Deployment owner | Gateway and backend admin-service route |
| `GATEWAY_URL` | Deployment owner | Server-only gateway URL used by SvelteKit |
| `PORT` | Deployment owner | Per-process listening port |
| `HOST` | Deployment owner | Admin-app listening interface |
| `SESSION_TTL_MINUTES` | Backend owner | Bidding-session lifetime |

Service URLs are routing configuration, not passwords. They may be shared in
normal team documentation unless the host topology itself is confidential.
Internal services should not be publicly reachable merely because their URLs
are non-secret.

The untracked `.env` service URLs are for processes launched directly on the
host. Docker Compose deliberately uses Compose service names such as
`http://passenger-service:8081`; `127.0.0.1` inside a container refers only to
that container and must not be used for container-to-container routing.

### Email and web deployment

| Name | Owner | Use |
|---|---|---|
| `SMTP_HOST` | Email/infrastructure owner | Authentication email server |
| `SMTP_PORT` | Email/infrastructure owner | Authentication email server port |
| `SMTP_USER` | Email/infrastructure owner | Authentication email identity |
| `SMTP_PASS` | Email/infrastructure owner | Authentication email credential |
| `SMTP_FROM` | Product/infrastructure owner | Sender identity |
| `PUBLIC_MAPBOX_TOKEN` | Mapbox account owner | Public browser token for the dispatch map |
| `ORIGIN` | Deployment owner | Public HTTPS origin expected by SvelteKit |
| `ADMIN_APP_ORIGIN` | Deployment owner | Compose input for the public admin origin |

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

1. Copy the root `.env.example` to an untracked `.env` and have the responsible
   owners populate its values.
2. Install dependencies in each backend service that will be run and in
   `apps/admin_app`.
3. Start PostgreSQL.
4. Back up the target database, review and apply the additive migrations in
   the order below, then seed admin configuration.
5. Provision the private owner.
6. Start auth, passenger, driver, trip, bidding, fare, admin, and gateway
   services. Start telemetry and chat when testing those existing features.
7. Start `apps/admin_app` with `bun run dev`.
8. Open `http://localhost:5173`.

In each Bun project, dependency installation and development startup are:

```sh
bun install
bun run dev
```

Useful local health URLs are the gateway at `http://localhost:8080`, auth at
`http://localhost:8088`, and admin-service at `http://localhost:8089`. A health
response proves only that the process is listening; complete the acceptance
checks before treating the system as ready.

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

| Order | Owner | Reviewed files |
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

Docker Compose is intended for local development and for adapting to the
teammate-managed host.

```sh
docker compose config
docker compose up -d postgres-db
```

On a new PostgreSQL volume,
`server/database/init/001-create-service-databases.sql` creates the auth,
driver, trip, bidding, chat, and admin databases. The existing fare tables
remain in the passenger database unless the deployment deliberately assigns
`FARE_DATABASE_URL_DOCKER` to another migrated database.

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

For a public deployment, terminate TLS at a teammate-managed reverse proxy,
send the dashboard domain to the `admin-app` container, keep service ports on a
private network, and set the SvelteKit origin to the exact HTTPS URL.

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

## Service-credit rules

- Store and transmit money as integer centavos.
- Store rates as basis points. The initial `1,000` basis-point rate is 10%.
- The minimum top-up is 10,000 centavos (₱100).
- The credited wallet balance may not exceed 100,000 centavos (₱1,000).
- A driver may sign in and inspect history while blocked. Ride acceptance is
  blocked whenever available credit cannot cover that ride's exact commission.
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
destination belongs to BaoBao and that the person reviewing payments can see
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

The teammate or infrastructure owner must provide:

- A host that can run the SvelteKit Node adapter and Bun services.
- Dashboard DNS, HTTPS certificate, TLS termination, and reverse-proxy routing.
- Database URLs, database roles, backups, restore testing, and migration access.
- A matching `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN`, delivered securely.
- All service URLs and private network/service-discovery rules.
- A public, origin-restricted Mapbox token.
- SMTP configuration when passenger/driver email flows are in scope.
- The top-up destination's public account display information and a person
  authorized to verify incoming payments.
- The owner email recipient, privately shared initial credential procedure, and
  representative passenger/driver test accounts.
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
  tokens.
- Reports: filters and pagination, CSV totals against source records, Manila
  display time, and clean browser Print / Save as PDF output.
- Frontend: Svelte checks, unit tests, production build, login cookie behavior,
  10-second refresh, tablet layout, Mapbox unavailable state, and owner workflow.
- Platform: service type checks/tests, migration tests, `docker compose config`,
  clean image builds, container health, private-service reachability, and a
  Docker smoke test.

Final acceptance is one traceable flow: provision the owner, approve a driver,
verify the required documents, activate selected barangays, approve a real
test top-up, normally or manually assign a ride, complete cash settlement,
handle a complaint/restriction, and export the resulting reports.

## Code and documentation convention

Backend work follows route → controller → service → repository, two-space
TypeScript formatting, single quotes, semicolons, and Zod validation. Use
selective `/** ... */` [JSDoc](https://jsdoc.app/about-getting-started) comments
for important exported operations and business invariants. Do not comment
obvious code and do not add a generated JSDoc website for this MVP.
