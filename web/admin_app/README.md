# EasyRide operations portal

SvelteKit owner dashboard for EasyRide operations in Pagadian City. Browser
requests go to this server first so the eight-hour admin JWT remains in an
HttpOnly, SameSite cookie and is never available to client JavaScript.

## Local setup

1. Copy `.env.example` to `.env`.
2. Set `GATEWAY_URL` to the API gateway (normally `http://localhost:8080`).
3. Set `PUBLIC_MAPBOX_TOKEN` to a public Mapbox token. Never use a secret token.
4. Run `bun install`, then `bun run dev`.
5. Open `http://localhost:5173` and sign in with the privately provisioned owner.

The gateway, auth service, admin service, and their databases must be running.
The dashboard still renders a clear unavailable state when an API is offline.

## Environment

| Name | Owner | Purpose |
|---|---|---|
| `GATEWAY_URL` | Backend/deployment | Server-only API gateway base URL |
| `PUBLIC_MAPBOX_TOKEN` | Mapbox account owner | Public browser token for dispatch maps |
| `ORIGIN` | Deployment | Public HTTPS dashboard origin used by adapter-node |
| `HOST` | Deployment | Listening host; Docker uses `0.0.0.0` |
| `PORT` | Deployment | Listening port; Docker uses `5173` |

Do not put JWTs, owner passwords, e-wallet credentials, PINs, or secret Mapbox
tokens in this app's environment.

## Checks and production

```sh
bun run check
bun test
bun run build
docker build -t easyride-admin-app .
```

Run the image with the environment above. Terminate TLS at the teammate-managed
reverse proxy and set `ORIGIN` to that HTTPS URL. CSV downloads are proxied
through SvelteKit so the admin credential is never included in a download URL.
