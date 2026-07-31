# Driver service operations

This service owns driver operating approval, document checklists, restrictions,
service credits, top-up requests, and ride commission reservations.

## Configuration

Copy `.env.example` to an untracked environment file and set:

- `DATABASE_URL`: the same driver database used by auth-service.
- `JWT_SECRET`: the shared JWT signing secret.
- `INTERNAL_SERVICE_TOKEN`: shared only by backend services.
- `TRIP_SERVICE_URL`: trip-service base URL.
- `PORT`: defaults to `8082`.

Never put actual secret values, wallet passwords, PINs, or private Mapbox tokens
in Git.

## Migration

Back up the driver database, review
`drizzle/0000_driver_operations.sql`, and apply it through the deployment's
normal migration process. For a local PostgreSQL database:

```sh
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f drizzle/0000_driver_operations.sql
```

The migration is additive. Existing drivers become `pending`; the owner must
approve them before they can go online or accept new rides. The credit ledger
is protected by a database trigger against updates and deletes, so rollback
must preserve it rather than dropping it.

## HTTP boundaries

- `/drivers/me/*` requires a driver bearer token. The token identity is always
  used instead of a driver ID supplied by the client.
- `/drivers/internal/*` requires `x-internal-service-token`. Mutations also
  require `Idempotency-Key`; `x-service-name` identifies the caller.
- `/drivers/admin/*` requires `x-internal-service-token`. Mutations also require
  `x-admin-id` and `Idempotency-Key`.

Trip and bidding services use:

- `GET /drivers/internal/:id/profile`
- `POST /drivers/internal/eligibility`
- `POST /drivers/internal/credits/reservations`
- `POST /drivers/internal/credits/reservations/:rideId/settle`
- `POST /drivers/internal/credits/reservations/:rideId/release`
- `POST /drivers/internal/credits/reservations/:rideId/dispute`

All money values are integer centavos. Commission defaults to 1,000 basis
points (10%). Top-ups are ₱100 minimum, and purchased credits may not exceed
₱1,000. A reservation holds commission at assignment, settlement deducts it,
cancellation releases it, and dispute keeps it held for review. Wallet
responses set `lowBalance` at ₱50 or less so the driver app can warn before the
next few rides consume the remaining credit.

## Checks

```sh
bunx tsc --noEmit
bun test tests/unit/driver_operations.test.ts
```

The database transaction checks in
`tests/integration/driver_operations.test.ts` require a disposable migrated
PostgreSQL database and `RUN_DRIVER_OPERATIONS_INTEGRATION=1`. They truncate
their target database; never point them at staging or production.
