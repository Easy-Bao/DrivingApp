---
name: code-security-audit
description: OWASP-oriented security audit of this driving app codebase, including Flutter passenger/driver clients, shared Dart packages, Go gateway/core/realtime services, admin TypeScript, Docker, and persistence/messaging configuration. Analyze against ASVS 5.0.0, API Security Top 10 2023, OWASP secure-coding guidance, and WSTG-style verification. Use when the user requests a security audit, vulnerability assessment, security review, or code security analysis.
---

# Code Security Audit for Driving App

## Purpose

Perform a systematic, evidence-backed security audit across the repository’s trust boundaries. Identify exploitable weaknesses, map them to the applicable OWASP taxonomy when the mapping is defensible, explain existing controls and limitations, and produce a prioritized Markdown report. Do not make fixes during an audit unless explicitly requested.

Preserve user changes. Never print or copy secrets, modify live data, deploy, rotate credentials, run intrusive tests against external systems, or claim a dynamic verification passed without authorization and evidence.

## Audit input

Accept:

- **Codebase path:** active workspace by default; narrow to `server/`, `apps/`, `packages/`, `web/admin_app/`, or selected files when requested.
- **Audit level:** L2 by default; use L1 for baseline triage and L3 only when the system’s mission-critical requirements justify the extra scope.
- **Focus areas:** authentication, authorization, injection, cryptography, API security, session, file handling, data protection, configuration, or secure coding.
- **Technology context:** infer from the repository, then confirm Go, Dart/Flutter, TypeScript/SvelteKit, PostgreSQL/Ent, Redis, RabbitMQ, reverse proxy, and Docker boundaries.

Read [audit_process.md](references/audit_process.md) before broad audits. Read only the domain references needed for the selected scope, then use [report_format.md](references/report_format.md) for the final output.

## OWASP source roles

- **ASVS 5.0.0:** verification baseline for applicable controls across validation, auth, authorization, cryptography, API, configuration, and secure coding.
- **API Security Top 10 2023:** risk taxonomy for BOLA, broken authentication, property/function authorization, unrestricted resource consumption, SSRF, misconfiguration, inventory, and unsafe API consumption.
- **OWASP Cheat Sheet Series:** remediation patterns, not proof that a control is present.
- **WSTG:** safe verification ideas and test scenarios; execute dynamic tests only within authorized scope.

Do not invent exact ASVS, API, CWE, or WSTG identifiers. Map an item to a precise identifier only when it is verified from an available source; otherwise report the domain and describe the control in plain language.

## Audit workflow

1. **Reconnaissance:** map entrypoints, services, dependencies, trust boundaries, secrets/configuration, data stores, queues, files, and public routes.
2. **Scope definition:** select level and focus domains; record excluded directories, generated code, unavailable services, and assumptions.
3. **Domain analysis:** read complete relevant files, trace input to sinks, inspect middleware and tests, and distinguish confirmed findings from hardening suggestions.
4. **Cross-source correlation:** deduplicate one root cause appearing in multiple layers; attach OWASP mappings and remediation guidance only where supported.
5. **Risk ranking:** classify severity, confidence, exploit preconditions, affected roles/data, and remediation order.
6. **Report generation:** produce executive summary, findings table, domain notes, remediation roadmap, audit metadata, and limitations.

## Repository-specific scope

- **Flutter clients/packages:** token/session storage, API base URLs, Dio logging, route extras/deep links, response parsing, Mapbox/location permissions, background telemetry, local persistence, and client-side authorization assumptions.
- **Go API gateway:** public route allow-listing, reverse proxy targets, forwarded headers, CORS/security headers, timeout/body limits, WebSocket forwarding, and private upstream exposure.
- **Go core/realtime:** JWT/OTP/password flows, ownership and role checks, rides/bids/fares/wallet/reviews, document uploads, location/telemetry, chat, provider calls, Redis, RabbitMQ, PostgreSQL/Ent, concurrency, retries, and idempotency.
- **Admin TypeScript/SvelteKit:** server-only session handling, gateway calls, authorization, CSV/report exposure, browser security, and error leakage.
- **Docker/configuration:** exposed ports, environment variables, default secrets, startup dependencies, health checks, migration safety, TLS assumptions, and service isolation.

## Audit levels

- **L1:** essential baseline for every app: injection, basic authentication/authorization, secret handling, unsafe file access, critical API exposure, and high-impact misconfiguration.
- **L2:** default for this project because it handles identity, location, documents, rides, financial/fare data, and realtime communication. Add SSRF, resource abuse, session/OTP lifecycle, privacy, error/logging, WebSocket, and defense-in-depth checks.
- **L3:** use only when explicitly requested or justified by a mission-critical deployment. Include exhaustive canonicalization, advanced cryptographic verification, supply-chain/deployment review, and deeper operational testing.

## Focus catalog

| Focus | Primary checks |
|---|---|
| authentication | JWT validation, password/OTP/reset lifecycle, secret strength and rotation |
| authorization | BOLA/object ownership, function/role checks, property-level response filtering |
| injection | SQL/Ent, shell, URL/SSRF, template, log, JSON, header, and path injection |
| cryptography | password hashing, random tokens, constant-time comparisons, TLS, key handling |
| api-security | rate limits, body/pagination bounds, timeouts, retries, WebSockets, API inventory |
| session | token storage, expiration, fixation, revocation/purpose, CSRF/cookie behavior |
| file-handling | traversal, symlinks, upload limits, content validation, private storage/downloads |
| data-protection | location, PII, documents, financial data, logs, analytics, client exposure |
| configuration | CORS, headers, environment defaults, proxy bindings, error handling, Docker |
| secure-coding | concurrency, resource ownership, state machines, error paths, safe architecture |

## Severity and confidence

- **Critical:** directly exploitable RCE, injection, credential theft, authentication/authorization bypass, severe data breach, destructive integrity failure, or reliable service-wide DoS.
- **High:** serious broken access control, SSRF, weak cryptography, sensitive document/location exposure, or high-impact integrity/resource abuse.
- **Medium:** conditional exploitability, bounded disclosure, session/OTP weakness, missing API limits, unsafe defaults, or meaningful defense-in-depth gap.
- **Low:** limited hardening or observability improvement with no direct demonstrated exploit.
- **Info:** observation or recommendation without a security impact.

Use High/Medium/Low confidence. Confidence reflects evidence quality, not severity. Trace the full data flow before escalating a pattern; record upstream controls and the verification needed for indirect findings.

## Required report

Use [report_format.md](references/report_format.md). Include scope, audit level, methodology, executive posture, findings with file/line evidence, OWASP mapping where verified, impact, confidence, remediation, verification status, prioritized roadmap, and limitations. Separate confirmed vulnerabilities from recommendations.

## Safe verification

Run read-only reconnaissance and existing tests first. For Go, use the narrowest applicable tests, `go vet`, race tests, and `govulncheck`/`gosec` only when installed or authorized to install. For Flutter and TypeScript, run existing analyzers/tests without exposing `.env` values. Dynamic API/WebSocket testing requires an authorized local/test target, bounded inputs, and no production credentials.

Never report “secure” as an absolute conclusion. Report the audited scope, evidence, excluded areas, and residual risk.

## References

- [audit_process.md](references/audit_process.md): reconnaissance, scope, evidence, and synthesis procedure.
- [security_domains.md](references/security_domains.md): project-tailored domain checklist and OWASP crosswalk.
- [vulnerability_patterns.md](references/vulnerability_patterns.md): code-level patterns to investigate in this repository.
- [remediation_patterns.md](references/remediation_patterns.md): safe fix patterns for Go, Dart, TypeScript, and Docker.
- [report_format.md](references/report_format.md): Markdown report contract.
