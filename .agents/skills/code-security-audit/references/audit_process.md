# Security Audit Process

## 1. Reconnaissance

Start read-only:

```bash
git status --short
rg --files -g '!**/.dart_tool/**' -g '!**/build/**' -g '!**/node_modules/**' | sort
rg -n "ListenAndServe|http\.Server|RegisterRoutes|WebSocket|Dio|BaseOptions|JWT|bcrypt|argon|password|OTP|Authorization|redis|rabbit|postgres|DATABASE_URL|JWT_SECRET|MAPBOX|ports:|environment:" server apps packages web docker-compose.yml
```

Map:

- public entrypoints and route prefixes;
- authentication and identity propagation;
- sensitive data stores and flows;
- external providers and outbound URLs;
- file uploads and storage paths;
- asynchronous queues, cache keys, retries, and background workers;
- client/admin consumers of each API contract;
- environment and deployment assumptions.

Do not print values from `.env`, secrets, tokens, passwords, or private identifiers.

## 2. Define scope and controls

Record the audit path, level, focus areas, commit/worktree state, tools available, and unavailable dependencies/services. Read middleware, router, DTO, domain, use case, repository, and tests around each trust boundary. Generated Ent code and lockfiles receive consistency checks unless the issue concerns their source/manifest.

## 3. Analyze data flows

For each finding, write a compact chain:

```text
source -> parser/validation -> middleware/authorization -> business logic -> sink -> observable impact
```

Check whether each layer validates independently, whether identity comes from a verified token, whether the response exposes more than the requester may see, and whether errors/retries alter the security result.

## 4. Use safe tests

Prefer existing negative tests and local unit tests. Add tests only when the user requests implementation. Do not fuzz production services, brute-force OTPs, upload malicious documents to live storage, or run exploit payloads against external hosts. Dynamic verification must use an explicitly authorized local/test endpoint.

## 5. Synthesize

Deduplicate one root cause across Flutter, gateway, core, and admin layers. Rank by exploitability and blast radius, not by how many files mention the pattern. Keep recommendations separate from confirmed vulnerabilities. Do not use an OWASP identifier as decoration; map only verified controls.

## 6. Report limitations

State when runtime services, authenticated role accounts, Android/iOS devices, Mapbox, Redis, RabbitMQ, PostgreSQL, dependency scanners, or network access were unavailable. Distinguish “not tested” from “passed.”
