# EasyRide repository current state

Last verified: 2026-08-01 (Asia/Manila)

This file records the checked-out code, runtime, and verification state. Product
decisions belong in `product-plan.md`; Admin operations and deployment guidance
belong in `admin-mvp.md`. Do not place credentials or secret values here.

## Git state

- Checkout: clean pull-request integration worktree
- Current branch: `codex/admin-service-mvp-pr`
- Official upstream: `Easy-Bao/DrivingApp`
- Fork: `zenon-dev98/DrivingApp`
- Live upstream `main`: `2b9f422`
- The branch is based directly on live upstream `2b9f422` and contains
  additive Admin implementation, security, and documentation commits.
- The upstream Android/Mapbox configuration, auth and telemetry refactors, and
  location-service architecture are now integrated.
- This is the review branch for a draft pull request against official `main`;
  verify publication status and review activity on GitHub rather than relying
  on a copied commit hash in this file.

Upstream `2b9f422` restructures the Flutter apps/packages into PascalCase paths
and replaces several service-package implementations. This branch starts at
that commit. The required Driver, Passenger, and CoreModels contract changes
were manually ported to the new PascalCase paths rather than reviving deleted
lowercase trees.

This pull-request worktree is separate from the original working folder. The
user's uncommitted logo and meeting-document work remains excluded and
recoverable there. Upstream tracks logo paths that differ only by letter case;
those logo directories are intentionally excluded from this Windows sparse
worktree so the Admin integration cannot overwrite either variant.

## Tooling and devices

- Git: 2.53.0 for Windows
- Bun: 1.3.14
- Flutter: 3.44.7 stable
- Dart: 3.12.2
- Docker Engine: 29.5.3
- Docker Compose: 5.1.4
- Detected Flutter targets: Windows, Chrome, and Edge
- No Android emulator or physical Android device is currently detected.
- ADB 37 is installed, but `adb devices -l` currently returns no authorized
  Android target.

## Local runtime

Docker Compose configuration currently renders successfully with fifteen
services. The current file publishes only PostgreSQL `5432`, the gateway
`8080`, and the Admin app `5173`; backend ports are private to the Compose
network. Admin-service remains on internal port `8089`, while the integrated
location-service now consistently uses internal port `8090`.

Docker Desktop is running. All fifteen Compose services are up. The Admin login
is available at `http://localhost:5173/login` and the API gateway at
`http://localhost:8080`. The preserved PostgreSQL volume was not removed or
reset. Admin, Driver, Passenger, and Fare additive migrations apply cleanly;
Fare now targets the dedicated `fare_db` and its seed completes.

Verified live gateway calls include Fare estimate and real location search,
nearby-place, and route responses. Location nearby results currently expose
`address`, `lat`, `lng`, and `distance_km`; the checked-out Flutter normalization
and contract tests handle those fields.

### Physical Android connectivity

The Passenger and Driver apps contain separate physical-device configuration
and distinct Android application IDs, so they can run on separate targets or be
installed together on one phone. Their current ignored `.env` files use
`PHYSICAL_DEVICE=false` and `http://localhost:8080`; on Android, that maps to
the emulator-only `10.0.2.2` address.

No Android emulator or authorized physical device was detected in the latest
check. When Docker is running, recheck ownership of host port `8080` before
using USB `adb reverse`; the same-Wi-Fi alternative may require an explicit
Windows Firewall Private-profile rule. No real-phone connection has been
verified yet.

### Reported mobile issues

On 2026-07-31, Xy reported:

- Nearby locations are not detected or displayed reliably when the Passenger
  destination-search field receives focus.
- An unspecified animation appears janky.

These reports are not reproduced on a device. Upstream commits `38399eb`
through `7eabfc8`, which substantially replace location resolution and service
configuration, and the later structural commit `2b9f422` are integrated.

A read-only upstream audit identified two concrete nearby-location risks:

- Focusing the destination field only starts its expansion animation; it does
  not retry failed GPS or nearby-place loading.
- The new Go location service emits `address`, `lat`, `lng`, and `distance_km`.
  The checked-out PascalCase Flutter model now normalizes those names, and a
  focused contract test passes.

Reproduce the location behavior on a real target. The animation report still
needs the exact screen,
triggering action, device, and preferably a short recording. The current
destination-search expansion is a likely hotspot because one `AnimatedBuilder`
rebuilds a large stack containing the native Mapbox view, clipping, shadow,
search controls, and result list every frame; this is not yet a confirmed
runtime diagnosis.

The nearby-location defect is a functional dependency of the final
Passenger-to-Driver-to-Admin acceptance flow. The animation report is a
separate mobile-quality issue unless it blocks interaction or causes a crash.

## Admin implementation state

This is not a from-scratch project. Commit `5e81359` added a broad Admin MVP
prototype across the Admin frontend, Admin backend, authentication, gateway,
Driver, Passenger, Trip, Bidding, Fare, Docker, database migrations, and limited
mobile integration.

Present in the current code:

- One-owner authentication, provisioning, login lock, session cookie, and
  logout
- Admin overview and operational queues
- Driver approval, generic document requirements/review, restrictions, driver
  prepaid-balance ledger, top-ups, adjustments, and refunds
- Pagadian barangay roster, development geometry, and active-zone checks
- Open-request and active-trip dispatch data with manual assignment
- Fare-rule and commission-policy administration
- Basic complaint cases and linked account restrictions
- CSV reports, printable report pages, and append-only Admin audit events
- Driver prepaid-balance and top-up UI in the Driver app
- Passenger-facing propagation of selected backend booking errors

Partial or unverified:

- The frontend is API-wired and builds. Its login, route-guard, and error states
  pass desktop/tablet browser checks, and an authenticated SvelteKit session
  exported and rendered controlled reports. The remaining mutation sections
  still need authenticated visual acceptance.
- Driver identity-document evidence, vehicle records, passenger records, and
  detailed trip records do not yet have complete Admin workflows.
- Many Admin actions use raw IDs and tolerant untyped response parsing.
- The current dispatch path uses bidding sessions and driver offers, not the
  confirmed five-nearest fixed-fare passenger-selection direction.
- The current fare UI and service configuration still include base, per-km,
  per-minute, minimum, and surge fields rather than the discussed first-km plus
  succeeding-km MVP formula.
- Shared and Premium capacity, stop, availability, and Premium-pricing contracts
  are not implemented as a consistent cross-service workflow.
- Cross-service mutations are idempotent sagas rather than one distributed
  transaction. The current success and cancellation/retry paths reconcile, but
  broader partial-service failure recovery remains focused-test evidence only.
- Protected CSV and print routes reconcile against a controlled multi-service
  ride dataset. Browser Print / Save as PDF still needs visual acceptance.
- Private identity-document object storage, signed access, retention, and the
  driver application-intake browser flow are not complete.
- The required mobile integration files are ported into the PascalCase
  `Apps/` and `Packages/` trees from upstream `2b9f422`.
- The Admin frontend now lives under `web/admin_app`; `Apps/` contains only the
  Passenger and Driver Flutter clients.

## Verification evidence

### After the upstream replay on this checkout

- No unresolved merge entries or conflict markers remain.
- No tracked legacy lowercase `apps/` or `packages/` replacement paths remain.
- Docker Compose configuration renders successfully with fifteen services.
- Compose reports expected warnings because this clean review worktree does not
  contain local database, SMTP, Mapbox, JWT, or internal-service secret values.
- Admin frontend `bun run check`: 0 errors and 0 warnings.
- Admin frontend tests: 11 passed.
- Admin frontend production build: passed with adapter-node; the Mapbox client
  chunk exceeds Vite's default 500 kB warning threshold.
- Admin-service TypeScript check: passed.
- Auth-service TypeScript check: passed.
- API-gateway suite: 5 passed.
- API-gateway TypeScript check: passed.
- CoreModels tests: 4 passed; analysis completed without errors or warnings and
  retained 20 upstream PascalCase filename-style notices.
- Admin-service default tests: 30 passed and 4 database-backed cases skipped.
- Auth-service focused owner/Admin and email-privacy tests: 11 passed; database
  route suites are exposed separately and require disposable Passenger/Driver
  database URLs.
- Passenger and Driver Flutter analyses were rerun as recorded below. Their
  ignored `.env` files are absent, the sparse worktree excludes the upstream
  case-colliding SharedUi logo assets, and no Android target is running.

### Latest pull-request readiness check

- Database-free default suites now pass for Admin (30), Auth (11), Driver (12),
  Passenger (6), Trip (10), Bidding (12), and Fare (2). Database-backed suites
  remain explicit integration commands and still require disposable migrated
  databases.
- Driver and Passenger `flutter analyze --no-pub` do not pass on this branch:
  Driver reports 367 issues and Passenger reports 569 issues. The first failures
  include malformed or missing imports, unresolved session/config types, stale
  test contracts, missing generated sources, and absent ignored `.env` assets.
- The malformed Driver `AuthModule.dart` and much of the broken PascalCase
  import state are already present in upstream `2b9f422`; they were not created
  by the Admin commits. The Admin branch nevertheless cannot be described as a
  clean combined mobile build until upstream or a focused mobile repair resolves
  them.

### Earlier isolated prototype acceptance, before the upstream replay

- Owner provisioning, rotation, second-owner refusal, login lock, verified
  session cookie, protected route, and logout passed against disposable
  PostgreSQL and containerized HTTP services.
- Driver app analysis passed with 14 tests; Passenger app analysis passed with
  26 tests after refreshing local package metadata.
- Location-service image build: passed after correcting the Docker build
  context and adding the generated Go module lockfile.
- Location-service Go tests: passed inside the Go 1.22 container.
- Driver prepaid-balance/authentication unit tests: 8 passed.
- Trip safety, reservation, and reconciliation unit tests: 4 passed.
- Bidding identity, assignment, rollback, manual-assignment, and concurrency
  unit tests: 11 passed.
- Fare commission unit tests: 2 passed.
- Admin unit suite: 30 passed with 2 gated integration suites skipped by
  default; the real case/restriction database integration passed 2 tests.
- Admin-to-Driver compliance HTTP/database acceptance passed 1 test with 29
  assertions on freshly migrated PostgreSQL 16 tmpfs.
- Passenger restriction integration passed; full Driver database integration
  passed 4 tests with 69 assertions.
- Trip and Bidding focused unit suites pass; disposable PostgreSQL assignment
  races proved one Premium assignment and at most five Shared assignments per
  Driver, with one winner for competing normal/manual claims.
- Fare snapshot integrity, retry, non-retroactivity, immutability, and terminal
  status races pass on fresh and representative legacy migrations. The focused
  suite passed 8 tests; the seeded Fare suite passed 11.
- Report pagination/count/date/filter cases pass, including 205-row pagination
  and a 1,005-case export. Admin report integration passed on PostgreSQL.
- Core location contract tests pass 3 tests; canonical ride-status contract
  passes 1 test. Passenger blocker/bid-session tests pass 3 tests and the Driver
  blocker-message test passes.
- Live Docker smoke: gateway `200`, Fare estimate `200`, Admin/Driver protected
  routes `401` without credentials, Admin login `200`, location search returned
  9 places, nearby returned 10 places, and route calculation returned the
  expected current Go contract fields.
- A clean parallel `easyride-acceptance` Compose project built and started all
  fifteen services against its own PostgreSQL volume, applied reviewed
  migrations, and seeded Admin/Fare data.
- Its current offer-based end-to-end flow passed: owner login, Driver approval
  and requirement verification, one active development zone, synthetic top-up
  approval, Driver online, Solo Ride offer/acceptance, completion, ₱3 commission
  settlement from a ₱30 fare, complaint resolution, restriction enforcement
  and lifting, idempotent second acceptance/cancellation, and released credit.
- Controlled database counts reconciled one completed and one canceled ride,
  one settled and one canceled fare transaction, and matching reserve,
  release, settlement, top-up, case, and audit records. Authenticated SvelteKit
  CSV and print routes returned both rides.

Not completed:

- Android application builds after the upstream integration
- Passenger and Driver device login verification
- Safe Passenger/Driver OTP registration against a controlled SMTP test sink
- Final fixed-fare five-nearest Passenger -> Driver -> Admin mobile workflow;
  the accepted disposable flow exercises the current offer-based prototype
- Authenticated visual acceptance of all Admin mutation screens and browser
  Print / Save as PDF output
- Public-deployment, TLS, backup/restore, and production-boundary verification

## Immediate blockers and next sequence

1. Repair or replace the broken upstream PascalCase Flutter import/generation
   state, then rerun focused analyses/tests and build both Android apps once an
   emulator or authorized phone is available.
2. Resolve only the product decisions that block code: final matching contract,
   fare/commission rules, Shared/Premium rules, refund provenance, and support
   workflow.
3. Add a controlled SMTP/OTP sink and private document-evidence workflow, then
   verify real Android Passenger and Driver clients without recording test
   credentials in this repository.
4. Re-run the isolated owner-to-report acceptance on the final contracts, then
   visually accept the protected Admin sections and printable reports.

## Ticket queue

The canonical implementation queue is
[`docs/tickets/admin-prototype.md`](tickets/admin-prototype.md). No public
GitHub issues have been created. MOB-001 and MOB-002 remain separate mobile
defect tickets rather than being hidden inside an Admin ticket.
