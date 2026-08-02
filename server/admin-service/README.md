# EasyRide Admin service

The isolated Admin API owns the single owner credential, complaint cases,
idempotency records, and append-only audit events. It does not call or modify
Passenger, Driver, Trip, Bidding, Fare, or Auth services in this first slice.

## Local setup

1. Copy `.env.example` to an untracked `.env`.
2. Create the `admin_db` PostgreSQL database.
3. Run `bun install` and `bun run db:migrate`.
4. Run `bun run owner:provision` in an interactive terminal.
5. Run `bun run dev` and use the gateway at `/admin/*`.

Provisioning creates the first owner. Reusing the same normalized email rotates
its password and clears the login lock; a different second owner is refused.

## Verification

```sh
bun run typecheck
bun test
bun run db:check
```
