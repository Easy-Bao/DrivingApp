# EasyRide repository instructions

These instructions apply to the entire repository. Prefer the smallest safe
implementation and verification set that proves the requested change.

## Project context

- EasyRide is a Pagadian City Bao Bao ride-booking pilot.
- Passenger and Driver Flutter clients live under `apps/`; shared Dart code
  belongs under `packages/`.
- Backend services use Bun, TypeScript, Hono, Drizzle, Zod, and PostgreSQL under
  `server/`.
- The private SvelteKit operations portal lives at `web/admin_app`.
- The official upstream repository is `Easy-Bao/DrivingApp`; `origin` may be a
  contributor fork.

## Working and Git safety

- Inspect the relevant code, documentation, branch, and working tree first.
- Preserve unrelated and uncommitted work. Never discard it with reset, clean,
  or checkout commands.
- Make the smallest complete root-cause change; avoid speculative abstractions,
  unrelated refactors, mass formatting, and dependencies without a real need.
- Ask before destructive data operations, irreversible migrations, secret
  rotation, deployment, publication, or external messages.
- Check live upstream before claiming the checkout is current.
- Do not commit, push, or open a pull request unless requested.
- Never fabricate credentials, service responses, tests, or runtime results.

## TypeScript backend conventions

- Use two-space indentation, single quotes, semicolons, and the surrounding
  naming style.
- Validate HTTP input with Zod and use Drizzle with reviewed SQL migrations.
- Prefer typed literal unions or enums for finite domain states and stable public
  error codes for failures.
- Derive the acting identity from the verified JWT; never trust an ID supplied
  in a state-changing request body.
- Add selective `/** ... */` documentation only for important exported APIs,
  security or money invariants, and non-obvious failure behavior. Those comments
  narrate purpose, execution order, concurrency or timing, integration
  boundaries, and data contracts instead of paraphrasing the signature.

### Admin service structure

- Organize `server/admin-service/src/modules/<domain>/` vertically.
- Each Admin module uses `<domain>.schema.ts`, `<domain>.routes.ts`, and
  `<domain>.service.ts`. Do not add controller or repository layers unless the
  team first agrees that measured complexity requires them.
- Routes own Hono request/response handling. Services own business rules and
  Drizzle access.
- Shared middleware belongs under `src/common`, environment and database setup
  under `src/config`, and table definitions under `src/db/schema`.
- Do not add seeders, runtime mock records, speculative providers, or hardcoded
  credentials and service URLs.
- Admin endpoints remain unversioned until the team adopts a coordinated API
  versioning policy.
- Keep Driver, wallet/top-up, Trip, Bidding, Fare, and document-storage
  integrations out of the isolated Admin foundation. Add them later through
  reviewed contracts with their owning services.

## Flutter conventions

- Follow the nearest `analysis_options.yaml` and root Flutter lints.
- Use `dart format`, single quotes, trailing commas, immutable models, and the
  established Cubit/Bloc architecture.
- Do not manually edit generated `.g.dart` or `.freezed.dart` files.
- Keep app-specific UI in its app and reusable behavior in `packages/`.

## SvelteKit conventions

- Keep the Admin portal server-rendered, TypeScript-based, desktop-first, and
  tablet-usable.
- Store the Admin JWT only in a Secure, HttpOnly, SameSite cookie outside local
  development; browser JavaScript must never receive it.
- Use server loads and form actions to call the API gateway.
- Preserve keyboard access, visible focus, readable contrast, and explicit
  loading, empty, error, and restricted states.

## Security, money, and data

- Never commit or print passwords, OTPs, JWTs, database credentials, internal
  service tokens, wallet secrets, identity documents, or secret Mapbox tokens.
- Store money as integer centavos and rates as basis points.
- Driver balances cannot become negative; ledger and audit history are
  append-only.
- State-changing money and assignment operations require idempotency.
- Snapshot fare, commission rate, commission amount, and assignment source so
  later settings never alter an existing booking.
- Keep identity documents in private object storage and mask identity numbers in
  routine views and logs.
- Use additive migrations. Never use `db:push` against staging or production.

## Verification and documentation

- Backend changes: run the affected service tests and type checks.
- Gateway changes: run gateway tests and affected service tests.
- SvelteKit changes: run Svelte checks, focused tests, and production build.
- Authentication, money, migrations, or concurrency changes require focused
  negative and retry coverage.
- Never claim an end-to-end flow passed unless it actually ran.
- Run the relevant static analysis, tests, and build before staging or
  committing; resolve every applicable compiler error and warning first.
- Commit messages use a lowercase `<topic>: <summary>` header, one lowercase
  narrative paragraph without lists, and one or more final
  `changelog: <user-facing summary>` lines.
- Record confirmed behavior and gaps in `docs/product-plan.md`, verified runtime
  facts in `docs/repo-current-state.md`, and Admin architecture/startup in
  `docs/admin-mvp.md` without duplicating long specifications.
- Report outcome first, then changed areas, checks, risks, and incomplete work.
