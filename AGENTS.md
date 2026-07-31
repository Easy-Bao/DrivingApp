# EasyRide repository instructions

These instructions apply to the entire repository. Keep them lean: use the
smallest safe implementation and verification set that can prove the requested
change.

## Project context

- EasyRide is a Pagadian City ride-booking pilot for Bao Bao vehicles.
- Passenger and Driver clients are Flutter applications under `Apps/`.
- Shared Dart and Flutter code belongs under `Packages/`.
- Backend services use Bun, TypeScript, Hono, Drizzle, Zod, and PostgreSQL under
  `server/`.
- The private operations frontend lives at `web/admin_app`. Keep `Apps/` for
  the Passenger and Driver Flutter clients.
- The official upstream repository is `Easy-Bao/DrivingApp`. A configured
  `origin` may be a fork.

## Instruction and source priority

When instructions disagree, use this order:

1. Safety, privacy, security, prevention of data loss, and financial integrity.
2. The user's explicit current request.
3. Current schemas, migrations, routes, tests, and established behavior.
4. Last verified repository and runtime facts in
   `docs/repo-current-state.md`.
5. Confirmed decisions in `docs/product-plan.md`.
6. This file.
7. `docs/admin-mvp.md`, README files, and older supporting documents.

Do not silently invent behavior when a product decision remains open. Mark the
gap and ask only when the choice materially changes the implementation.

## Working approach

- Inspect the relevant implementation and working-tree state before editing.
- Preserve user changes and unrelated uncommitted files.
- Make the smallest complete root-cause change.
- Reuse existing components, services, schemas, helpers, tokens, and scripts.
- Avoid unrelated refactors, mass formatting, duplicate implementations, and
  speculative abstractions.
- Do not add a production dependency, framework, state-management library, or
  hosted service without explicit approval and a concrete need.
- Ask before destructive data operations, irreversible migrations, major
  architecture changes, secret rotation, publication, deployment, or external
  messages.
- Never fabricate credentials, service responses, test accounts, test results,
  production readiness, or unavailable dependencies.

## Git and repository safety

- Check the live upstream branch before claiming the checkout is current.
- Do not pull, merge, rebase, or switch branches over uncommitted work without
  first preserving and reporting that work.
- Resolve conflicts deliberately; never discard user changes with reset,
  checkout, or clean commands.
- Do not commit, push, open a pull request, or publish unless requested.
- Keep generated build output, credentials, local environment files, and
  identity documents out of Git.

## Dart and Flutter conventions

- Follow the nearest `analysis_options.yaml` and the root Flutter lints.
- Use `dart format` formatting, single quotes, trailing commas, and established
  package imports.
- Prefer `final`, `const`, immutable models, exhaustive states, and the existing
  Cubit/Bloc architecture.
- Keep app-specific UI under its app and reusable behavior under the appropriate
  package.
- Do not manually edit generated `.g.dart` or `.freezed.dart` files. Change the
  source declaration and regenerate through the repository's existing workflow.
- Keep Passenger and Driver contracts aligned with backend status values, IDs,
  errors, timestamps, and eligibility rules.

## TypeScript backend conventions

- Follow route -> controller -> service -> repository.
- Use two-space indentation, single quotes, semicolons, and the surrounding
  import and naming style.
- Validate request inputs with Zod at the boundary.
- Keep HTTP parsing and response concerns in controllers, business invariants in
  services, and database operations in repositories.
- Use Drizzle and reviewed SQL migrations rather than ad hoc database edits.
- Prefer explicit domain errors and stable public error codes.
- Derive authenticated identity from the verified JWT. Do not trust passenger,
  driver, or admin IDs supplied in request bodies for state-changing actions.
- Use `/** ... */` JSDoc comments selectively for important exported APIs,
  cross-service behavior, security or money invariants, and non-obvious failure
  handling. Do not repeat obvious code or TypeScript types, and do not add a
  generated JSDoc site unless requested.

## SvelteKit and Admin conventions

- Keep the private operations portal server-rendered and TypeScript-based.
- Store the Admin JWT only in a Secure, HttpOnly, SameSite cookie outside local
  development; browser JavaScript must never receive it.
- Use SvelteKit server loads and form actions to call the API gateway.
- Keep the public website and authenticated operations portal as separate
  deployment surfaces.
- Match established EasyRide mobile colors and interaction language where it
  improves consistency, without copying mobile layouts that are unsuitable for
  desktop operations.
- Keep the interface desktop-first and tablet-usable, with keyboard access,
  visible focus, readable contrast, and clear loading, empty, error, and
  restricted states.

## Cross-service invariants

- Mobile and web clients call the API gateway; Admin-service integrations call
  trusted backend routes using `INTERNAL_SERVICE_TOKEN`.
- The gateway must strip client-supplied internal-authentication headers.
- Use ISO-8601 UTC timestamps in APIs and display them in Asia/Manila time.
- Store money as integer centavos and rates as basis points.
- Driver prepaid balances cannot become negative. Ledger and audit history are
  append-only.
- State-changing money and assignment operations require idempotency protection.
- Snapshot fare, commission rate, commission amount, and assignment source so
  later configuration changes are not retroactive.
- Enforce driver approval, required documents, restrictions, service zones, and
  available commission balance in the backend even when a client bypasses UI.
- Keep Passenger, Driver, Trip, Bidding, Fare, and Admin statuses and identifiers
  synchronized. Document intentional translation at service boundaries.
- The current offer-based bidding implementation differs from the confirmed
  fixed-fare passenger-selection direction. Do not silently treat either as the
  final contract; follow `docs/product-plan.md` and expose the mismatch in plans,
  tests, and reviews.

## Security and privacy

- Never commit or print passwords, OTPs, JWTs, database credentials, internal
  service tokens, wallet secrets, recovery codes, or secret Mapbox tokens.
- Only a public, appropriately restricted Mapbox token may reach browser or
  Flutter client code.
- Keep driver identity documents in private object storage with short-lived
  access. Store metadata and object keys rather than public file URLs or
  database blobs.
- Mask identity numbers in routine views and logs.
- Do not log authentication payloads, payment credentials, full identity
  documents, or unnecessary personal information.
- Use least privilege for services and database roles. Public clients must not
  reach internal-only routes.

## Database and migration safety

- Use additive, reviewed migrations for shared environments.
- Never use `db:push` against staging or production.
- Back up and verify recovery before a shared-environment migration.
- Do not delete or rewrite credit ledgers, reservations, top-up history, fare
  transactions, audit events, or completed trip history as routine rollback.
- Run destructive integration tests only against a disposable migrated
  database.

## Risk-based verification

Run only checks that can detect regressions caused by the current diff. Do not
rerun an unchanged check after it passed unless relevant code, configuration,
generated output, or merge results changed.

- Documentation only: inspect the diff, links, paths, terminology, and factual
  claims. Do not build the applications.
- Dart or Flutter logic: format and analyze the affected app or package, then
  run focused tests.
- Android or platform configuration: build the affected application in addition
  to focused analysis.
- Backend service logic: run that service's focused Bun tests and type checks
  when available.
- Gateway or route wiring: run gateway tests and the affected service tests.
- SvelteKit UI or server actions: run Svelte checks, focused tests, and the
  production build when configuration or server behavior changes.
- Authentication, authorization, money, assignment concurrency, migrations, or
  cross-service contracts: add focused negative and retry cases and run the
  smallest relevant integration path.
- A complete Passenger -> Driver -> Admin ride test is required before claiming
  the combined system is operational, but not for unrelated documentation or
  isolated visual changes.

Never claim a test, build, device check, deployment, or end-to-end flow passed
unless it actually ran. Report exact blockers and unverified areas.

## Documentation boundaries

- Use `docs/product-plan.md` for confirmed app behavior, feature status, shared
  contracts, known gaps, and unresolved product decisions.
- Use `docs/repo-current-state.md` for the checked-out branch, upstream state,
  current paths, available scripts, verified checks, runtime status, and
  concrete implementation blockers.
- Use `docs/admin-mvp.md` for Admin architecture, configuration names, startup,
  migrations, operations, deployment, and acceptance checks.
- Keep meeting logistics in meeting files. Keep Discord organization, music
  channels, casual ideas, secrets, and personal credentials out of product and
  operations documentation.
- Update documentation when implementation or confirmed behavior changes, but
  do not duplicate the same long specification across multiple files.
- Update `docs/repo-current-state.md` after a meaningful merge, dependency or
  path change, successful build, completed integration slice, or newly confirmed
  blocker. Do not rewrite it for trivial edits.

## Tickets

- Tickets are optional, not a prerequisite for every change.
- Prefer GitHub Issues over a duplicate local `Tickets.md` when a shared ticket
  is useful.
- Use a short GitHub issue or scoped task when work spans multiple services,
  includes schema, money, authentication, security, or migrations, needs review
  across sessions, or requires explicit acceptance criteria.
- A substantial ticket records its goal, dependencies, allowed areas, areas not
  to touch, requirements, non-goals, acceptance criteria, and focused manual
  verification.
- Small fixes, documentation corrections, and focused tests may proceed without
  a ticket.
- Use one branch per coherent pull request rather than one branch per tiny edit.
  Keep unrelated tickets out of the same pull request.
- A ticket never overrides security, privacy, financial integrity, or confirmed
  product behavior.

## Completion reporting

Report the outcome first, followed by changed files, verification performed,
remaining risks, and anything incomplete. Keep the report proportional to the
change and avoid repetitive progress loops.
