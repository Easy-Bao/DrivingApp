# EasyRide operations portal

Private SvelteKit portal for the single EasyRide owner. The first isolated
Admin slice covers owner login, complaint cases, CSV reports, and audit history.
Passenger, Driver, top-up, dispatch, fare, and service-zone integrations are
deliberately outside this pull request.

## Local setup

1. Copy `.env.example` to an untracked `.env`.
2. Start the API gateway and Admin service.
3. Run `bun install` and `bun run dev`.
4. Open `http://localhost:5173`.

The SvelteKit server stores the eight-hour Admin JWT in an HttpOnly, SameSite
cookie. Browser JavaScript never receives that token.

## Environment

| Name | Purpose |
|---|---|
| `GATEWAY_URL` | Server-only API gateway URL |
| `ORIGIN` | Deployed HTTPS portal origin |
| `HOST` | Listening host |
| `PORT` | Listening port |

## Verification

```sh
bun run check
bun run test
bun run build
```
