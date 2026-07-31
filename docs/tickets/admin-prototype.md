# EasyRide Admin prototype ticket register

- **Reconstructed:** 2026-07-31
- **Prototype anchor:** local commit `5e81359` (`feat: add admin service MVP`)

## Purpose and provenance

The current Admin implementation was originally introduced as one broad
prototype change. This register decomposes that existing code into the smaller
tickets that would have made it easier to build, review, test, and discuss.

These are **reconstructed records**, not fabricated Git or GitHub history:

- The original commit remains unchanged.
- No claim is made that the code was originally written in this exact order.
- No GitHub issues, remote branches, or pull requests are created by this file.
- “Implemented” means a code surface exists. Only “Accepted” means every listed
  criterion has passed.

The sequence below is now the working review and hardening order. Existing code
should be reused and corrected; these tickets do not authorize rewriting
already working features from scratch.

Product behavior and unresolved decisions remain in
[the product plan](../product-plan.md). Architecture, setup, migrations, and
operational procedures remain in [the Admin guide](../admin-mvp.md).

## Ticket index

| ID | Ticket | Implementation maturity | Verification |
|---|---|---|---|
| ADM-001 | Synchronize upstream and establish a clean baseline | Accepted on `2b9f422` | Admin changes were replayed on the official PascalCase tree; unrelated local files remain excluded |
| ADM-002 | Establish the Admin API and database foundation | Accepted | Fresh, upgrade, seed, and start acceptance passed |
| ADM-003 | Provide private owner authentication | Accepted | Database and HTTP session flow passed |
| ADM-004 | Secure gateway and internal-service access | Accepted | Gateway, JWT, and internal-service acceptance passed |
| ADM-005 | Protect mutations with idempotency and audit records | Accepted | PostgreSQL concurrency and rollback acceptance passed |
| ADM-006 | Provide the dashboard shell and operational overview | Substantial UI prototype | Desktop/tablet login, error, and route-guard checks passed; authenticated report session passed |
| ADM-007 | Review driver approval and document compliance | Backend acceptance passed | Clean Admin-to-Driver HTTP/database proof passed; browser intake and evidence storage remain |
| ADM-008 | Handle complaints and account restrictions | Backend enforcement accepted | Service/database checks passed; complaint and support policy remains open |
| ADM-009 | Maintain driver service-credit balances | Substantial prototype | Database concurrency passed; closure policy pending |
| ADM-010 | Submit and review prepaid top-ups | Substantial prototype | Software acceptance passed; controlled payment pending |
| ADM-011 | Configure fares and commission policy | Snapshot integrity accepted; pricing provisional | Database/service invariants passed; final fare contract remains open |
| ADM-012 | Configure Pagadian service zones | Accepted software slice | Geometry, workflow, seed, and fail-closed checks passed |
| ADM-013 | Monitor dispatch and assign a driver manually | Concurrency slice accepted; contract mismatch remains | Real PostgreSQL assignment races passed; final matching flow pending |
| ADM-014 | Export reports and inspect audit history | Backend/export acceptance passed | Controlled data reconciled through protected CSV/print routes; visual print review remains |
| ADM-015 | Integrate Admin rules with Passenger and Driver | PascalCase contract slice implemented | CoreModels checks pass; full mobile/device E2E remains |
| ADM-016 | Prove the disposable-stack end-to-end workflow | Current-prototype software acceptance passed | Clean isolated success, retry/cancel, case, restriction, report, and audit flow passed |

## Reality check

- **Foundation accepted on this checkout:** ADM-001 through ADM-005. The branch
  is based directly on upstream `2b9f422`.
- **Additional backend slices accepted:** ADM-007 compliance enforcement,
  ADM-008 restriction enforcement, ADM-011 snapshot integrity, and ADM-013
  assignment concurrency.
- **Substantial but incomplete:** ADM-006, ADM-009, and ADM-010. ADM-014's
  backend/export path passed; protected print output still needs visual review.
- **Known product or integration gates:** ADM-008, ADM-009, ADM-011, ADM-013,
  and ADM-015.
- **Current-prototype system acceptance:** ADM-016 passed on an isolated stack,
  including completion, idempotent cancellation, finance reconciliation,
  cases, restrictions, reports, and audits.

Therefore, the repository now contains a working and substantially hardened
Admin prototype, but it is **not yet an accepted combined MVP**. The unresolved
matching/fare/Shared/Premium policies, remaining
authenticated visual operations, and Android-device checks still separate the
prototype from release readiness.

## ADM-001 — Synchronize upstream and establish a clean baseline

- **Type:** Completed ticket
- **Status:** Accepted
- **Dependencies:** None

### Goal

Preserve the Admin prototype and existing user files while integrating the
latest official Passenger, Driver, location, and platform changes. Produce a
baseline on which later ticket results are trustworthy.

### Included scope

- Preserve uncommitted documentation and logo files.
- Integrate the current `Easy-Bao/DrivingApp` upstream branch.
- Resolve Admin/gateway, Docker, and Driver-state conflicts deliberately.
- Reconcile service configuration introduced by upstream.
- Run focused checks for every conflict resolution.
- Record the resulting Git, runtime, and verification state.

### Non-goals

- Changing matching, fare, Shared, or Premium product behavior.
- Fixing the reported nearby-location or animation defects.
- Deploying, pushing, or opening a pull request.

### Evidence

- `docker-compose.yml`
- `server/api-gateway/src/config/gateway.config.ts`
- `server/api-gateway/src/routes/gateway.ts`
- `Apps/DriverApp/lib/src/Features/Home/Presentation/Bloc/DashboardState.dart`

### Acceptance criteria

- No unresolved merge entries or conflict markers remain.
- Existing Admin routes and the new location route are both preserved.
- Flutter generated state matches its source declaration.
- Focused gateway, Flutter, Admin, and Compose checks pass, or every blocker is
  recorded without claiming success.
- User-owned uncommitted files remain recoverable.

### Verification record

- Pull-request integration base: upstream `2b9f422`.
- No unresolved merge entries or conflict markers remain.
- Admin-service, Auth-service, and API-gateway tests and TypeScript checks pass.
- Admin Svelte checks, tests, and production build pass.
- Driver analysis and 14 tests pass.
- Passenger analysis and 26 tests pass after refreshing local package metadata.
- Docker Compose configuration renders successfully with fifteen services.
- Go location-service tests pass in the pinned Go 1.22 container, and its
  production image builds successfully.
- Existing logo and meeting-document edits remain recoverable and excluded from
  the pull-request branch.

On 2026-08-01, the Admin work was replayed on live upstream `2b9f422`. Required
Driver, Passenger, location-contract, and ride-status changes were manually
ported to the PascalCase tree. The upstream case-colliding logo paths remain
untouched, and the user's logo work remains recoverable in the original
worktree.

## ADM-002 — Establish the Admin API and database foundation

- **Type:** Completed reconstructed ticket
- **Status:** Accepted
- **Dependencies:** ADM-001

### Goal

Create a versioned Admin API with the repository's route → controller → service
→ repository structure and reviewed, additive persistence.

### Included scope

- Bun/Hono service on the configured Admin port.
- Zod request validation and common error handling.
- Drizzle connection, schema, migrations, and seed command.
- Admin-owned tables for audit events, mutation results, complaint cases,
  service zones, and commission policies.
- Health endpoint and Docker image.

### Non-goals

- Owning Driver, Passenger, Trip, Bidding, or Fare data inside Admin tables.
- Running `db:push` against a shared environment.

### Evidence

- `server/admin-service/src/index.ts`
- `server/admin-service/src/features/routes/admin.routes.ts`
- `server/admin-service/src/features/controllers/admin.controller.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `server/admin-service/src/features/repositories/admin.repository.ts`
- `server/admin-service/src/db/schema.ts`
- `server/admin-service/drizzle/0000_legal_sister_grimm.sql`
- `server/admin-service/drizzle/0001_colorful_mister_fear.sql`

### Acceptance criteria

- Type checking and focused service tests pass.
- Migrations apply once to a fresh disposable database and safely upgrade a
  representative existing database.
- Seed data loads without duplicates.
- The health endpoint starts with valid configuration and fails clearly when a
  required secret or database URL is absent.

### Verification record

- Admin tests: 6 passed; TypeScript and Drizzle migration checks passed.
- Missing or invalid startup configuration fails with configuration names and
  never prints their values.
- The container image starts and returns a healthy response with complete
  configuration.
- Both migrations apply to a fresh PostgreSQL 16 database and can be rerun.
- Migration `0001` upgrades a representative database containing migration
  `0000`; the mutation-results table and replacement audit index are correct.
- Two concurrent seeds produce exactly 54 zones and one initial 10% commission
  policy.
- Re-seeding preserves an already activated zone while refreshing roster,
  geometry, and attribution data.
- The database acceptance used temporary containers and tmpfs only; it did not
  alter the user's PostgreSQL volume.

## ADM-003 — Provide private owner authentication

- **Type:** Completed reconstructed ticket
- **Status:** Accepted
- **Dependencies:** ADM-001, ADM-002

### Goal

Allow one privately provisioned owner to sign in to the Admin portal without
public registration or a default password.

### Included scope

- Additive Admin-account migration and repository.
- Interactive first-owner provisioning and same-owner password rotation.
- Refusal to accidentally provision a different second owner.
- Password hashing, failed-attempt tracking, and timed login lock.
- Admin-role JWT with an eight-hour lifetime.
- SvelteKit login, logout, route guard, and HttpOnly SameSite session cookie.

### Non-goals

- Public Admin registration.
- Email reset or a default/shared password.
- Placing a JWT or password in browser JavaScript, Git, or documentation.

### Evidence

- `server/auth-service/migrations/0001_admin_auth_accounts.sql`
- `server/auth-service/src/features/routes/admin/admin.routes.ts`
- `server/auth-service/src/features/services/admin/admin.service.ts`
- `server/auth-service/src/features/repositories/admin/admin.repository.ts`
- `server/auth-service/src/scripts/provision_owner.ts`
- `server/auth-service/tests/admin.test.ts`
- `web/admin_app/src/routes/login/+page.server.ts`
- `web/admin_app/src/routes/logout/+server.ts`
- `web/admin_app/src/lib/server/session.ts`
- `web/admin_app/src/hooks.server.ts`

### Acceptance criteria

- First-owner provisioning, same-email rotation, and different-email refusal
  work against a disposable database.
- Correct login succeeds; invalid login, five-attempt lock, expiry, logout, and
  non-Admin rejection behave as documented.
- Browser inspection confirms the JWT is not accessible to client JavaScript.

### Verification record

- Auth-service Admin tests and TypeScript checks pass.
- A disposable PostgreSQL database accepted first-owner creation, same-owner
  password rotation with lock clearing, and refusal to replace the owner with a
  different email.
- Real HTTP login returned an eight-hour Admin JWT and the verification endpoint
  accepted it; invalid credentials and the five-attempt lock behaved as
  specified.
- Expired and signed non-Admin tokens are rejected.
- The SvelteKit route guard, logout, and session tests pass.
- A containerized SvelteKit/Auth/Gateway flow reached a protected page using an
  HttpOnly, SameSite=Strict, eight-hour cookie, then cleared it on logout.
- Loopback HTTP remains usable for local Docker testing; non-local production
  hosts require HTTPS for the Secure cookie.
- All database and HTTP acceptance data lived in temporary containers and was
  removed without creating or deleting a volume.

## ADM-004 — Secure gateway and internal-service access

- **Type:** Completed reconstructed ticket
- **Status:** Accepted
- **Dependencies:** ADM-002, ADM-003

### Goal

Expose Admin operations through the API gateway while preventing clients from
impersonating trusted backend services.

### Included scope

- Gateway service registry entry and `/admin/*` proxy route.
- Admin JWT verification for `/admin/v1/*`.
- Shared-token verification for `/admin/internal/*`.
- Removal of client-supplied internal-authentication headers at the gateway.
- Trusted Admin-service clients for Driver, Passenger, Trip, Bidding, and Fare.

### Non-goals

- Making internal service routes public.
- Treating service URLs as authentication credentials.

### Evidence

- `server/api-gateway/src/config/gateway.config.ts`
- `server/api-gateway/src/routes/gateway.ts`
- `server/api-gateway/src/proxy/gateway.proxy.ts`
- `server/api-gateway/tests/gateway.test.ts`
- `server/admin-service/src/shared/middleware/auth.ts`
- `server/admin-service/src/features/clients/admin.clients.ts`

### Acceptance criteria

- Valid Admin requests reach Admin-service through the gateway.
- Passenger, Driver, expired, malformed, and absent tokens are rejected.
- Client-supplied internal headers are stripped.
- Internal calls succeed only with the configured shared token.

### Verification record

- Gateway tests and TypeScript checks pass after the upstream synchronization.
- Admin and location requests route to their configured services, and missing
  Admin or location URLs fail with the missing configuration names.
- Client-supplied internal-authentication headers are removed while the
  verified bearer token is preserved.
- Admin middleware tests reject absent, malformed, expired, and Passenger
  credentials; a valid Admin token exposes only its verified identity.
- A live local gateway-to-Admin check returned `200` for an Admin token, `401`
  for absent, malformed, and expired tokens, and `403` for a Passenger token.
- A client-supplied internal token sent through the gateway was rejected, while
  the same configured token used directly between trusted services succeeded.

## ADM-005 — Protect mutations with idempotency and audit records

- **Type:** Completed reconstructed ticket
- **Status:** Accepted
- **Dependencies:** ADM-002, ADM-004

### Goal

Make retried Admin mutations safe and leave a reviewable record of who changed
what, why, and with what outcome.

### Included scope

- Require an idempotency key for Admin mutations.
- Save and replay completed mutation results.
- Append actor, operation, target, reason/reference, before/after state,
  outcome, request ID, and UTC time to the Admin audit history.
- Keep credentials, tokens, and wallet secrets out of audit payloads.

### Non-goals

- Replacing immutable financial ledger entries with general audit records.
- Allowing audit events to be edited through an Admin route.

### Evidence

- `server/admin-service/src/db/schema.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `server/admin-service/src/features/repositories/admin.repository.ts`
- `web/admin_app/src/lib/server/admin-api.ts`

### Acceptance criteria

- Repeating the same request returns the saved result exactly once.
- Reusing a key for a different operation, target, or payload is rejected.
- Successful and failed mutations produce sanitized audit records.
- The Admin-local mutation and its audit record cannot be partially committed.

### Verification record

- Request keys are bounded and bound to the action, target, and canonical
  payload hash.
- Concurrent identical requests against disposable PostgreSQL returned the
  stored response and produced exactly one mutation result and one successful
  audit event.
- Replaying the request performed no second update; changing the payload under
  the same key returned `409 IDEMPOTENCY_KEY_REUSED` without changing state.
- A forced failure after the local zone write rolled back the zone and mutation
  result while retaining one sanitized failure audit.
- Credential-like reason and error text was redacted.
- A representative `0001` to `0002` upgrade backfilled legacy rows and enforced
  the new required columns.
- The test used PostgreSQL tmpfs with no named volume and left the persistent
  project database untouched.

Cross-service writes remain separate transactions by design. The Admin service
forwards the same idempotency key, and each downstream service must enforce its
own exactly-once operation; those guarantees are accepted in their respective
tickets.

## ADM-006 — Provide the dashboard shell and operational overview

- **Type:** Reconstructed ticket
- **Status:** Substantial UI prototype; browser acceptance pending
- **Dependencies:** ADM-003, ADM-004, ADM-005

### Goal

Give the owner a desktop-first, tablet-usable operations portal with protected
navigation and a concise view of work that needs attention.

### Included scope

- Authenticated SvelteKit layout and navigation.
- Overview totals and operational queues.
- Loading, empty, error, and unavailable states.
- UTC-to-Asia/Manila display formatting.
- Ten-second refresh for operational views.

### Non-goals

- Final marketing-quality visual design.
- A native desktop application.

### Evidence

- `web/admin_app/src/routes/(admin)/+layout.server.ts`
- `web/admin_app/src/routes/(admin)/+layout.svelte`
- `web/admin_app/src/routes/(admin)/[section]/+page.server.ts`
- `web/admin_app/src/routes/(admin)/[section]/+page.svelte`
- `web/admin_app/src/lib/admin.ts`
- `web/admin_app/src/app.css`

### Acceptance criteria

- Unauthenticated access redirects to login.
- The owner can navigate every section with keyboard and tablet input.
- Loading, empty, service-unavailable, and stale-refresh behavior are clear.
- Overview totals reconcile with their source services.

### Verification record and remaining work

- The production SvelteKit build, checks, and focused tests pass.
- The rebuilt login page rendered cleanly at desktop and tablet sizes with no
  browser-console errors.
- An unauthenticated protected route redirected to login, and invalid synthetic
  credentials produced the expected accessible error state.

Authenticated owner navigation, keyboard acceptance across every protected
section, stale/service-unavailable states, and final source-total
reconciliation remain pending because the existing owner password was neither
read nor rotated for automation.

### Remaining deployment decision

The frontend now lives at `web/admin_app`. A purely static S3/CloudFront build
would require a different authentication design because the current HttpOnly
session, server loads, and form actions require a SvelteKit server runtime.

## ADM-007 — Review driver approval and document compliance

- **Type:** Reconstructed ticket
- **Status:** Backend acceptance passed; browser/evidence intake remains
- **Dependencies:** ADM-004, ADM-005, ADM-006

### Goal

Keep operational approval separate from email verification and prevent an
ineligible driver from going online or accepting a ride.

### Included scope

- List and filter drivers.
- Pending, approved, and rejected operational approval.
- Owner-managed document requirement names.
- Pending, verified, rejected, and expired document review results.
- Expiry, notes, reviewer, and review timestamp.
- Backend eligibility enforcement when clients bypass their UI.

### Non-goals

- Public document URLs or database image blobs.
- Final private object-storage upload and retention workflow.

### Evidence

- `server/admin-service/src/features/routes/admin.routes.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `server/driver-service/src/features/routes/driver_operations.routes.ts`
- `server/driver-service/src/features/services/driver_operations.service.ts`
- `server/driver-service/src/features/repositories/driver_operations.repository.ts`
- `server/driver-service/src/db/schemas/driver_operations.schema.ts`
- `web/admin_app/src/routes/(admin)/[section]/+page.server.ts`

### Acceptance criteria

- Approval and document changes require a reason and create audit events.
- Missing, rejected, or expired required documents prevent online/acceptance.
- Email verification alone never grants operational approval.
- Direct API attempts cannot bypass the rules.

### Verification record and remaining work

- A real loopback Admin-to-Driver HTTP test passed 29 assertions against fresh
  PostgreSQL 16 tmpfs after both services' migrations.
- It proved that email verification does not grant operational approval,
  reasons and audit events are retained, missing and expired requirements block
  online/reservation operations, and the internal route rejects a missing
  service token.
- Admin and Driver TypeScript checks passed; the disposable database was
  removed without touching the shared volume.

The private evidence upload/object-storage workflow and the full browser
application-intake workflow remain separate unfinished slices.

## ADM-008 — Handle complaints and account restrictions

- **Type:** Reconstructed ticket
- **Status:** Backend enforcement accepted; product rules remain
- **Dependencies:** ADM-005, ADM-007

### Goal

Record basic complaints and allow the owner to apply or lift a temporary or
indefinite restriction without erasing account history.

### Included scope

- Cases targeting a ride, Passenger, or Driver.
- Open, under-review, resolved, and dismissed statuses.
- Category, notes, resolution, and optional linked restriction.
- Driver and Passenger restriction creation and lifting.
- Restricted users remain able to sign in and inspect permitted history while
  ride actions are blocked.

### Non-goals

- Automated legal or emergency escalation.
- Deleting financial, ride, complaint, or audit history.

### Evidence

- `server/admin-service/src/db/schema.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `server/passenger-service/src/db/schemas/restrictions.schema.ts`
- `server/passenger-service/src/features/routes/passenger.routes.ts`
- `server/driver-service/src/features/routes/driver_operations.routes.ts`
- `web/admin_app/src/routes/(admin)/[section]/+page.svelte`

### Acceptance criteria

- Case and restriction transitions are validated and audited.
- Restricted accounts cannot create, offer, accept, or start rides.
- Sign-in, permitted history, balance, reason, and support information remain
  available.
- Expired and lifted restrictions no longer block activity.

### Remaining decisions

Complaint categories, escalation steps, support wording, and response targets
remain product decisions.

The software checks now cover validated case transitions, linked restriction
targets, future/indefinite expiry, idempotent Passenger restrictions, and
backend enforcement across Passenger, Driver, Trip, and Bidding operations.
Those checks do not decide the remaining support policy.

## ADM-009 — Maintain driver service-credit balances

- **Type:** Reconstructed ticket
- **Status:** Substantial prototype; database concurrency accepted, closure policy pending
- **Dependencies:** ADM-005, ADM-007

### Goal

Maintain prepaid Driver service credit through an immutable centavo ledger
without permitting a negative balance.

### Included scope

- Balance and immutable ledger views.
- Audited owner credit adjustments.
- Verified account-closure refunds.
- Integer-centavo storage and maximum purchased-credit balance enforcement.
- Driver mobile balance, ledger, and blocking-state surfaces.

### Non-goals

- Holding Passenger cash fare in the service-credit wallet.
- Storing e-wallet credentials or making an automated e-wallet integration.

### Evidence

- `server/driver-service/src/db/schemas/driver_operations.schema.ts`
- `server/driver-service/src/features/services/driver_operations.service.ts`
- `server/driver-service/src/features/repositories/driver_operations.repository.ts`
- `server/driver-service/tests/unit/driver_operations.test.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `Apps/DriverApp/lib/src/Features/Profile/Presentation/Screens/service_credits_screen.dart`

### Acceptance criteria

- Balance equals the immutable ledger sum.
- Concurrent operations cannot create a negative balance.
- Adjustments and refunds are idempotent, authorized, reasoned, and audited.
- Only verified paid, unused credit is refundable during account closure.

### Verification record and remaining gap

- A disposable PostgreSQL concurrency test proved same-key adjustment and
  refund replay, same-ride reservation replay, single settlement, and rejection
  of a refund that would consume reserved commission.
- The final wallet balance and reserved amount exactly matched the immutable
  ledger sums, with one entry per adjustment, refund, reserve, and settlement.
- The append-only database trigger rejected an attempted ledger update.
- The test used tmpfs with no named volume and did not touch shared data.

Account-closure eligibility and paid-credit provenance are still an unresolved
policy and implementation slice. Until that is defined, a generic owner refund
must not be described as a verified account-closure refund.

## ADM-010 — Submit and review prepaid top-ups

- **Type:** Reconstructed ticket
- **Status:** Software accepted; controlled operational payment check pending
- **Dependencies:** ADM-009

### Goal

Let a Driver submit an external-payment reference and let the owner approve or
reject it exactly once after independently checking the receiving account.

### Included scope

- Owner-configured public top-up channels and instructions.
- Driver amount, sender name, and transaction-reference submission.
- Pending history and owner review queue.
- ₱100 minimum and ₱1,000 purchased-credit balance cap.
- Duplicate normalized-reference rejection.
- Idempotent approve/reject operation and ledger credit on approval.

### Non-goals

- Screenshot storage.
- Wallet password, PIN, recovery code, or private payment API storage.
- Automatic payment-provider reconciliation.

### Evidence

- `server/driver-service/src/features/routes/driver_operations.routes.ts`
- `server/driver-service/src/features/services/driver_operations.service.ts`
- `server/driver-service/src/features/repositories/driver_operations.repository.ts`
- `server/admin-service/src/features/routes/admin.routes.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `Apps/DriverApp/lib/src/Features/Profile/Presentation/Screens/service_credits_screen.dart`
- `web/admin_app/src/routes/(admin)/[section]/+page.server.ts`

### Acceptance criteria

- Repeated and concurrent approval credits exactly once.
- Duplicate references, below-minimum amounts, and balance-cap violations are
  rejected without changing the ledger.
- Approval/rejection reason and reviewer are retained.
- External-payment and internal-ledger totals can be reconciled.

### Verification record and remaining gap

- Four integration cases with 60 assertions passed against disposable
  PostgreSQL after all Driver migrations.
- The tests proved the ₱100 minimum, exact ₱1,000 cap, normalized duplicate
  detection, authenticated Driver identity, and retained reviewer, reason, and
  timestamp.
- Concurrent repeated approvals and rejections replay exactly once; a direct
  approve-versus-reject race has one winner.
- Approved-request totals, top-up ledger totals, and wallet balance reconcile,
  with one ledger row per approved request.
- The test used tmpfs with no named volume and left shared data untouched.

Software acceptance is complete. Operational acceptance still requires the
owner to compare one controlled real payment with the configured receiving
account before approving it; payment-provider automation remains outside the
MVP.

## ADM-011 — Configure fares and commission policy

- **Type:** Reconstructed ticket
- **Status:** Snapshot integrity accepted; pricing contract unresolved
- **Dependencies:** ADM-005, ADM-009

### Goal

Allow reviewed fare and commission configuration while preserving the exact
policy used by an existing ride.

### Included scope

- Fare-rule read/update endpoints and Admin controls.
- Commission rates stored in basis points.
- Initial 10% policy seed.
- Future commission scheduling and notice date.
- Fare, rate, amount, and assignment-source snapshots.

### Non-goals

- Treating provisional rates as approved production pricing.
- Applying a later configuration change retroactively to an existing ride.

### Evidence

- `server/fare-service/src/features/routes/fare.routes.ts`
- `server/fare-service/src/features/services/fare_calculation.service.ts`
- `server/fare-service/src/features/services/pricing_config.service.ts`
- `server/fare-service/src/features/services/commission.ts`
- `server/fare-service/tests/commission.test.ts`
- `server/admin-service/src/db/schema.ts`
- `server/admin-service/src/features/services/admin.service.ts`

### Acceptance criteria

- Centavo and basis-point calculations are exact and follow one documented
  rounding rule.
- A ride retains its original fare and commission snapshots.
- Commission changes cannot affect existing assignments.
- Notice enforcement begins from the approved first-real-ride date.

### Verification record

- Exact half-up centavo/basis-point validation now exists in service code and a
  reviewed additive PostgreSQL constraint.
- Fare snapshots reject inconsistent commission tuples, later-rate changes do
  not alter existing assignments, and snapshot monetary fields and rows cannot
  be updated or deleted.
- `payment_status` and `updated_at` remain mutable only through the allowed
  conditional transitions.
- Fresh and representative legacy migrations passed on disposable PostgreSQL
  16; the focused suite passed 8 tests and the seeded Fare suite passed 11.

### Remaining decisions

The team has not finalized the first-kilometre, succeeding-kilometre, minimum,
rounding, Shared, Premium, or surge rules. The existing configurable formula
must not be treated as final pricing.

## ADM-012 — Configure Pagadian service zones

- **Type:** Completed reconstructed ticket
- **Status:** Accepted software slice; launch gates remain
- **Dependencies:** ADM-002, ADM-005

### Goal

Let the owner activate selected Pagadian barangays and reject rides whose
pickup or destination falls outside active pilot coverage.

### Included scope

- Current 54-name Pagadian barangay roster.
- All barangays inactive on initial seed.
- Interim development geometry and source attribution.
- Point-in-polygon handling, including boundary points.
- Owner activation/deactivation and internal pickup/destination check.

### Non-goals

- Guessing the 18 pilot barangays.
- Treating interim HDX geometry as approved public-launch authority.

### Evidence

- `server/admin-service/src/db/seed.ts`
- `server/admin-service/src/db/pagadian-barangays.geojson`
- `server/admin-service/src/features/services/zone.service.ts`
- `server/admin-service/tests/zone.service.test.ts`
- `server/admin-service/tests/pagadian-geometry.test.ts`
- `web/admin_app/src/routes/(admin)/[section]/+page.svelte`

### Acceptance criteria

- The seed contains 54 unique barangay codes and remains idempotent.
- Inactive, inside, outside, and polygon-boundary cases behave predictably.
- Both pickup and destination must pass.
- Every mutation is reasoned and audited.

### Verification record

- The seed contains 54 unique Pagadian barangay codes, is concurrency-safe, and
  preserves an existing activation state when rerun.
- Point-in-polygon checks accept inside and boundary points and reject outside
  points.
- Workflow checks fail closed when no barangay is active and require both
  pickup and destination to fall within active geometry.
- The live internal endpoint returns `SERVICE_ZONE_NOT_CONFIGURED` while all
  barangays remain inactive.
- Zone mutations require a reason, share the Admin transaction/idempotency
  seam, and produce a sanitized audit event.

The team must still choose the pilot barangays at runtime. Public enforcement
also remains gated on Pagadian LGU/NAMRIA verification or written acceptance
of the interim attributed geometry; software acceptance does not approve that
boundary data for launch.

## ADM-013 — Monitor dispatch and assign a driver manually

- **Type:** Reconstructed ticket
- **Status:** Assignment concurrency accepted; matching contract and E2E remain
- **Dependencies:** ADM-007, ADM-009, ADM-011, ADM-012

### Goal

Show open requests and active trips and let the owner assign a Driver without
bypassing the normal safety, fare, zone, or service-credit rules.

### Included scope

- Dispatch data aggregation.
- Mapbox view for requests and active trips.
- Manual assignment action with a reason and idempotency key.
- Reuse of backend eligibility, fare snapshot, and commission reservation.

### Non-goals

- A special owner override for an ineligible Driver.
- New WebSocket infrastructure; operational pages use polling.

### Evidence

- `web/admin_app/src/lib/components/DispatchMap.svelte`
- `web/admin_app/src/routes/(admin)/[section]/+page.server.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `server/bidding-service/src/features/routes/bidding.routes.ts`
- `server/bidding-service/src/features/services/bidding.service.ts`
- `server/bidding-service/tests/unit/bidding.service.test.ts`
- `server/trip-service/src/features/services/ride.service.ts`

### Acceptance criteria

- Only one assignment wins when requests collide.
- Normal and manual assignment apply identical eligibility rules.
- The exact commission is reserved atomically with successful assignment.
- Retry, downstream failure, cancellation, completion, and unpaid-cash states
  reconcile without a double charge or negative balance.

### Known gap

Real PostgreSQL races now prove that only one normal/manual claim wins and that
the Trip service enforces one Premium or at most five Shared assignments per
Driver. Retry and compensation unit paths also pass.

The current dispatch path is built around bidding sessions and Driver offers.
That differs from the discussed fixed-fare, five-nearest Passenger selection
model and must not be silently accepted as the final matching contract.

## ADM-014 — Export reports and inspect audit history

- **Type:** Reconstructed ticket
- **Status:** Substantial prototype; print and full source reconciliation remain
- **Dependencies:** ADM-005, ADM-008 through ADM-013

### Goal

Give the owner filtered operational reports, CSV downloads, printable browser
views, and searchable audit history.

### Included scope

- Trips, commissions, top-ups, compliance, and cases reports.
- CSV generation through SvelteKit so the Admin token is not placed in a URL.
- Browser Print / Save as PDF routes.
- Audit list and date/status filters.

### Non-goals

- A separate PDF-generation service.
- Editing or deleting audit history.

### Evidence

- `server/admin-service/src/features/routes/admin.routes.ts`
- `server/admin-service/src/features/services/admin.service.ts`
- `web/admin_app/src/routes/(admin)/reports/[report].csv/+server.ts`
- `web/admin_app/src/routes/(admin)/print/[report]/+page.server.ts`
- `web/admin_app/src/routes/(admin)/print/[report]/+page.svelte`
- `web/admin_app/src/lib/server/csv.ts`
- `web/admin_app/src/lib/server/csv.spec.ts`

### Acceptance criteria

- Filters and pagination are applied consistently.
- CSV rows and totals reconcile with complete source records.
- Manila display time is correct while exported timestamps remain unambiguous.
- Printable routes render cleanly in a supported browser.

### Verification record and remaining work

- Overview counts now consume source totals rather than the first fetched page.
- CSV collection traverses every source page; a 205-row pagination case and a
  1,005-case batch export passed.
- Report-specific status validation, Manila date boundaries, compliance filter
  translation, and paginated cases/audits have focused coverage.
- Admin tests, TypeScript, Svelte checks/tests, and production build pass; real
  database case/audit pagination also passed.

ADM-016 created a controlled completed/canceled ride dataset. Trips,
commissions, top-ups, compliance, cases, and audit results reconciled through
the Admin API, and authenticated SvelteKit CSV and print routes returned both
rides. The printable page still needs visual browser and Print / Save as PDF
acceptance.

## ADM-015 — Integrate Admin rules with Passenger and Driver

- **Type:** Reconstructed ticket
- **Status:** PascalCase contract slice implemented; full mobile/device E2E remains
- **Dependencies:** ADM-007 through ADM-013

### Goal

Expose the backend's approval, restriction, zone, service-credit, and top-up
rules clearly in the Passenger and Driver applications.

### Included scope

- Driver balance, ledger, top-up form, and top-up history.
- Driver operating status and backend eligibility checks.
- Passenger propagation of selected booking failure codes.
- Stable backend codes for insufficient credit, inactive zones, unapproved
  Drivers, and restricted accounts.

### Non-goals

- Final visual treatment by the frontend specialist.
- Google authentication.

### Evidence

- `Apps/DriverApp/lib/src/Core/Network/DriverOperationsClient.dart`
- `Apps/DriverApp/lib/src/Features/Home/Presentation/Bloc/DashboardCubit.dart`
- `Apps/DriverApp/lib/src/Features/Profile/Presentation/Screens/service_credits_screen.dart`
- `Apps/PassengerApp/lib/src/Features/Booking/Data/DataSources/BiddingRemoteDataSource.dart`
- `Apps/PassengerApp/lib/src/Features/Trip/Presentation/Bloc/BookingBloc.dart`
- `server/driver-service/src/features/routes/driver_operations.routes.ts`
- `server/passenger-service/src/features/routes/passenger.routes.ts`

### Acceptance criteria

- Clients show precise, actionable blocking reasons.
- Bypassing a client screen does not bypass the backend rule.
- One verified Passenger and approved Driver complete the supported flow on
  real Android targets.
- Mobile fields and statuses match the backend contracts.

### Verification record and known gaps

- Passenger mappings cover the six stable booking blocker codes.
- Driver messages distinguish approval/document/credit/restriction blockers.
- Bid-session assignment now reads `rideId`, polling reads
  `accepted_trip_id`, and canonical ride statuses serialize as `in_transit`
  and `canceled` while retaining legacy parsing.
- Focused Core, Passenger-service, Passenger-app, and Driver-app analyses/tests
  pass. Live location search, nearby places, and route calculation also return
  real data through the rebuilt gateway.

The verified changes are ported into the PascalCase Flutter/package paths from
upstream `2b9f422`. No Android device is connected, and a real cross-app ride
and driver registration/verification UX remain unverified.

## ADM-016 — Prove the disposable-stack end-to-end workflow

- **Type:** Planned acceptance ticket
- **Status:** Current-prototype software acceptance passed; final product and device acceptance remain
- **Dependencies:** ADM-001 through ADM-015

### Goal

Prove that the prototype behaves as one system before the team calls it an
Admin MVP.

### Included scope

- Build a clean disposable Docker stack without deleting the existing local
  database volume.
- Apply reviewed migrations and seed configuration.
- Provision and sign in the owner.
- Verify a Driver's requirements and approval.
- Activate one explicitly approved test zone.
- Submit and approve a controlled top-up.
- Assign, complete, cancel, and reconcile representative rides.
- Handle a complaint/restriction.
- Export and reconcile the resulting reports and audit events.
- Record exact commands, checks, failures, and environment ownership.

### Non-goals

- Public deployment.
- Real production fares, pilot barangays, or unapproved boundary enforcement.
- Using personal credentials or real customer data.

### Evidence

- `docker-compose.yml`
- `server/database/init/001-create-service-databases.sql`
- `.env.example`
- `docs/admin-mvp.md`

### Acceptance criteria

- All required service images build and start with healthy dependencies.
- The complete owner → Driver → top-up → ride → settlement → case → report
  flow passes against disposable data.
- Retried operations reconcile exactly once.
- No password, token, OTP, wallet secret, or private document appears in logs,
  Git, screenshots, or test artifacts.
- Remaining launch gates are explicitly separated from software acceptance.

### Verification record and remaining gates

On 2026-08-01, a parallel `easyride-acceptance` Compose project used its own
PostgreSQL volume and host ports. All fifteen services built and started, the
reviewed migrations and Admin/Fare seeds completed, and no preserved local
database was reset.

A synthetic owner, Passenger, and Driver completed the current supported
offer-based workflow:

- The owner approved the Driver, verified a requirement, activated one
  development zone, configured a top-up channel, and approved a synthetic
  ₱100 top-up.
- The Driver went online; the Passenger created a Solo Ride bidding session;
  the offer was accepted; and the ride moved through `arrived`, `in_transit`,
  and `completed`.
- A ₱30 fare reserved and settled exactly ₱3 commission, leaving the Driver's
  prepaid balance at ₱97.
- A complaint was created and resolved. A restriction blocked the Driver from
  going online with HTTP `409`, then was lifted.
- A second ride proved repeated acceptance returns the same ride, repeated
  cancellation remains `canceled`, the reservation is released, and the
  available balance remains ₱97.
- Trip, commission, top-up, compliance, case, and audit reports contained the
  controlled records. Authenticated SvelteKit CSV and print routes returned the
  completed and canceled rides.

This accepts the software path of the **current prototype**, not the final
product contract. Passenger and Driver verification was inserted directly into
the disposable database because there is no controlled SMTP/OTP test sink. The
flow used synthetic money, development geometry, and the existing offer model;
it did not test a real e-wallet, private document uploads, Android clients,
Shared/Premium behavior, or the planned fixed-fare five-nearest workflow.
After recording the evidence, the isolated containers, network, and disposable
PostgreSQL volume were removed. The normal local stack and
`ride-app_postgres_data` remained running and intact.

## How to continue from this register

1. Preserve this uncommitted ticket batch, then finish ADM-001 by porting it to
   upstream `2b9f422` without changing product behavior.
2. Re-run the focused Flutter checks and build both Android apps on an emulator
   or authorized phone.
3. Resolve the product decisions that block the final contracts: matching,
   fare/commission, Shared/Premium, refunds, and support.
4. Add a controlled SMTP/OTP test sink and private document-evidence workflow.
5. Re-run the system acceptance against the final contracts and visually
   accept the protected Admin workflows and printable reports.

No ticket should be marked **Accepted** solely because its files compile or its
screen renders.
