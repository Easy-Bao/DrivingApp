# EasyRide Admin foundation

## Pull request scope

This first Admin pull request is deliberately isolated from the existing mobile
and backend services. It adds:

- one privately provisioned owner account inside `server/admin-service`;
- an eight-hour Admin JWT signed with a dedicated `ADMIN_JWT_SECRET`;
- complaint-case intake and reviewed status transitions;
- idempotent Admin mutations and append-only audit events;
- CSV exports for cases and audits;
- the private SvelteKit portal under `web/admin_app`;
- API gateway, PostgreSQL, Docker Compose, and CI wiring required by that slice.

It does not modify Auth, Passenger, Driver, Trip, Bidding, Chat, Fare, telemetry,
location, or either Flutter application.

## Deliberately deferred

Driver approval, document review, top-ups, service credits, restrictions,
dispatch, fares, commissions, and mobile integration need shared contracts with
the services that own those records. They must arrive in later reviewed pull
requests instead of being simulated or duplicated inside Admin.

### Deferred Driver Management contract

The later Driver Management module will compose the following operational view:

```text
Driver Management
├── Driver Profile (User Identity, Contact, Status)
├── Vehicles (Plate No, Model, Color, Type)
├── Driver Documents (KYC Docs, Expiry Dates, Verification Status)
├── Driver Credits & Wallet (Prepaid Balance, Earnings, Ledger)
├── Driver Offenses (Violations, Fines, Suspensions)
└── Performance Metrics (Ratings, Completion)
```

Admin will review or operate this information through contracts with the Auth,
Driver, Trip, and future finance owners. This Admin database must not create a
second copy of Driver identity, vehicle, wallet, ledger, or performance records.
No Driver Management route or table is included until those contracts are
agreed and tested with the existing mobile backend.

## Service-zone decision

Barangay activation and polygon enforcement have been removed. The current
product direction does not limit Bao Bao pickup eligibility by an Admin-managed
barangay switch, and the team does not yet have operational evidence that such a
restriction is needed. The pilot may still publish a human-readable coverage
area, while any legally required route or franchise restriction remains a launch
decision requiring Pagadian transport-authority confirmation.

Reintroduce geographic enforcement only when a written operating rule requires
it and the team has an approved boundary source. No barangay seed, GeoJSON data,
Mapbox dependency, or internal zone-checking endpoint is included now.

## Type safety

Zod validates login, query, and mutation inputs at the HTTP boundary. Drizzle
defines the PostgreSQL schema and preserves literal TypeScript unions for case
targets, case statuses, audit outcomes, Admin actions, and Admin target types.

The Admin service follows Xy's domain-module convention:

```text
src/
├── common/middleware/
├── config/
├── db/schema/
└── modules/
    ├── auth/
    ├── audit-log/
    ├── case-management/
    └── reporting/
```

Each module contains only its Zod schema, Hono routes, and service. Routes own
HTTP parsing and responses; services own business invariants and Drizzle access.
There are no separate controller or repository layers in this MVP.

Admin endpoints are deliberately unversioned for now: `/admin/auth`,
`/admin/overview`, `/admin/cases`, `/admin/audits`, and `/admin/reports`.
Version prefixes will be introduced only with a coordinated API-version policy.

## Configuration

Secret values never enter Git. Required names are:

- `DATABASE_URL`
- `ADMIN_JWT_SECRET`
- `ADMIN_SERVICE_URL` in the gateway
- `GATEWAY_URL`, `ORIGIN`, `HOST`, and `PORT` in the portal

Committed `.env.example` files contain names only for secrets. Real URLs,
credentials, and signing material belong only in untracked `.env` files or the
deployment secret store.

The Admin API defaults to port `8090` because the existing location service owns
port `8089`. The portal defaults to port `5173`.

## Local startup without Docker

1. Install Bun and PostgreSQL.
2. Create an `admin_db` database.
3. Copy the Admin service and portal `.env.example` files to untracked `.env`
   files and provide the real values.
4. In `server/admin-service`, run `bun install` and `bun run db:migrate`.
5. Run `bun run owner:provision` interactively.
6. Start the Admin service, API gateway, and `web/admin_app`.
7. Open `http://localhost:5173`.

Docker Compose is optional. On a new PostgreSQL volume it creates `admin_db`;
existing volumes require creating that database deliberately before migration.

## Verification before merge

Run:

```sh
cd server/admin-service
bun run typecheck
bun test
bun run db:check

cd ../../web/admin_app
bun run check
bun run test
bun run build
```

Also run the gateway tests, validate `docker compose config`, inspect the
generated migration, and confirm every GitHub check is green. A merge accepts
the isolated Admin foundation into development; it does not claim the combined
Passenger, Driver, and Admin system is production-ready.
