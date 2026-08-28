# EasyRide operations portal

Private SvelteKit portal for the single EasyRide owner. The first isolated
Admin slice covers owner login, complaint cases, CSV reports, and audit history.
Passenger, Driver, top-up, dispatch, fare, and service-zone integrations are
deliberately outside this pull request.

## Local setup

1. Create an untracked `.env` with `API_BASE_URL`, `ORIGIN`, `HOST`, and `PORT`.
2. Start the Go API and Admin service.
3. Run `bun install` and `bun run dev`.
4. Open the URL configured by `ORIGIN`.

The SvelteKit server stores the eight-hour Admin JWT in an HttpOnly, SameSite
cookie. Browser JavaScript never receives that token.

The portal calls the unversioned `/admin/*` API routes. API versioning is
deferred until the backend team adopts one policy across services.

## Environment

| Name | Purpose |
|---|---|
| `API_BASE_URL` | Server-only public API URL |
| `ORIGIN` | Deployed HTTPS portal origin |
| `HOST` | Listening host |
| `PORT` | Listening port |

## Verification

```sh
bun run check
bun run test
bun run build
```
