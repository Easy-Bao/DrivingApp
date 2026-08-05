# Remediation Patterns

## Go

- Parse and bound input at handlers; use `http.MaxBytesReader`, strict JSON decoding where appropriate, typed DTOs, allow-listed enums, and domain validation.
- Use Ent predicates or parameterized SQL; keep authorization predicates adjacent to resource queries.
- Use `crypto/rand` for secrets, vetted password hashing, `subtle.ConstantTimeCompare` for sensitive byte comparisons, and fail-closed secret validation.
- Use fixed/allow-listed outbound hosts and structured URL construction; set context deadlines and close response bodies.
- Apply rate limits, request/response limits, idempotency, transactions, bounded retries, and circuit breakers to state-changing or expensive flows.
- Store private documents behind generated keys, validate content/size, reject traversal, and authorize every read.
- Return stable generic errors while logging sanitized correlation-rich diagnostics.

## Flutter/Dart

- Keep server authority on the server; use client checks only for UX.
- Use secure storage for session secrets, avoid debug logging of headers/tokens, and keep environment tokens scoped to their intended public/private role.
- Construct URIs with `Uri`/structured Dio parameters; do not interpolate secrets or unencoded query values.
- Validate response shapes before state transitions, and make route extras/deep-link parameters non-authoritative and fully validated.
- Avoid retaining precise location or document data longer than the feature requires.

## TypeScript/SvelteKit

- Keep admin tokens in Secure, HttpOnly, SameSite cookies; call the gateway server-side and never expose secrets to browser JavaScript.
- Validate form/action input, enforce server-side authorization, escape rendered values, and constrain CSV/report exports.
- Keep session and API errors generic while preserving server-side diagnostics.

## Docker and operations

- Keep databases, Redis, RabbitMQ, core API, and realtime services private; expose only intended gateway/admin ports.
- Require secrets through environment/secret management, avoid defaults in production, and never bake secrets into images.
- Use health checks, startup ordering, timeouts, least-privilege identities, TLS at the deployment boundary, and additive migrations.
- Pin dependencies and run vulnerability scanners in CI when available.

## Verification pattern

For each fix, add a negative test that reproduces the rejected request and a positive test proving the valid path remains available. Then run the narrowest affected tests, static analysis, and dependency scan; document unavailable checks.
