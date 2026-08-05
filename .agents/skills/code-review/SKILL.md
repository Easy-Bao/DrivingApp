---
name: code-review
description: Production-oriented review of git changes across this driving app monorepo. Supports staged changes, commits, commit ranges, and file-scoped reviews with impact tracing, breaking-change detection, confidence-aware findings, and risk-weighted verdicts. Use when reviewing a PR, commit, range, staged diff, or selected application/server files.
---

# Code Review for Driving App

## Review contract

Review behavior, compatibility, reliability, security, and test evidence. Start from the exact git target, read complete surrounding context, trace affected consumers, and report only evidence-backed findings. Do not silently change files during a review unless the user also requests implementation.

Preserve all existing user changes. Do not reset, clean, checkout, commit, push, or enter a worktree without explicit authorization. Read [git_operations.md](references/git_operations.md) before handling commit ranges, root commits, merge commits, or ambiguous targets.

## Workflow

### 1. Determine and state the target

Interpret the request in this order:

| User input | Review target |
|---|---|
| Commit hash | That commit |
| `start..end` or `start~end` | The requested range, normalized to earliest through latest |
| File paths | The requested paths within the selected target |
| “review” with no hash | Staged changes; if none are staged, `HEAD` |

Confirm the resolved target in the working update before deep analysis. If the target is empty, say so and inspect status rather than reviewing unrelated files.

### 2. Retrieve and classify the diff

Use `git --no-pager show`, `git diff`, and `git status`; use the reference workflow for edge cases. Classify changed files as source, tests, configuration, documentation, build/CI, dependencies, generated, lock, vendor, mechanical rename, or formatting-only.

Review source, security/auth, authorization, persistence/schema, routing, runtime entrypoints, and production configuration in full. For generated, lock, vendor, rename-only, and format-only changes, verify integrity and consistency without spending line-by-line review effort on generated output.

Review depth:

- 1–10 files: full line-by-line review with context.
- 11–30 files: full-review source/config and prioritize tests and contracts.
- 30+ files: separate noise first, then fully review high-risk paths and sample low-risk changes.

### 3. Understand behavior and trace impact

Read the complete changed files and relevant callers, contracts, middleware, repositories, tests, and configuration. Determine:

- what behavior changed and whether it matches the stated intent;
- whether inputs, outputs, routes, claims, models, status codes, or storage schemas changed;
- which passenger/driver Flutter features, shared Dart packages, Go services, gateway routes, realtime consumers, admin pages, jobs, or tests consume the change;
- whether failures are bounded, observable, retry-safe, and recoverable;
- whether a required field, narrowed enum, removed symbol, changed URL, changed auth rule, or changed response shape breaks normalized consumers.

Use [impact_detection.md](references/impact_detection.md) for this repository’s tracing map.

### 4. Evaluate findings

Check correctness, edge cases, authorization, error handling, concurrency, resource bounds, persistence consistency, API compatibility, configuration semantics, observability, and test coverage. Apply the confidence rules below; do not escalate a speculative issue without stating the missing evidence.

| Severity | Meaning |
|---|---|
| Critical | Security exposure, auth bypass, irreversible data loss, core transaction corruption, crash/deadlock, unbounded resource exhaustion, or incompatible public contract with active consumers |
| Major | Incorrect behavior, reliability degradation, recoverable data inconsistency, high operational cost, concurrency defect, swallowed failure, or dangerous config drift |
| Minor | Maintainability, duplication, limited edge case, incomplete coverage, or medium-term quality concern |
| Nit | Low-impact polish, naming, comments, or formatting |

| Confidence | Evidence |
|---|---|
| High | Directly demonstrated by the diff, call graph, tests, or deterministic control flow |
| Medium | Credible impact with one indirect assumption or unverified runtime dependency |
| Low | Plausible but weakly evidenced; request manual verification and avoid automatic escalation |

A Major finding is a `REQUEST_CHANGES` candidate when it affects authentication, payment/fare or wallet integrity, data integrity, availability, or a widely consumed contract and confidence is Medium or High.

### 5. Decide the verdict

Use the baseline rules, then apply risk-weighted judgment internally:

- `REQUEST_CHANGES`: any Critical finding or 3+ Major findings.
- `COMMENT`: 1–2 Major findings or 5+ Minor findings.
- `APPROVE`: only Minor/Nit findings or no findings.

Weights are Critical=10, Major=5, Minor=2, Nit=1. Multiply by confidence High=1.0, Medium=0.7, Low=0.4; add +4 for each finding in auth, payment/fare, data integrity, or availability. A score of 12+ with Medium/High confidence supports `REQUEST_CHANGES`; 6–11 supports `COMMENT`; ≤5 with no Major+ finding supports `APPROVE`. Do not output this internal score.

### 6. Report

Use [output_format.md](references/output_format.md). Group by severity by default. Every finding must include location, issue, evidence, impact, confidence, and a concrete suggestion. Include strengths when warranted, limitations when checks could not run, and a clear verdict rationale.

## Project review priorities

- **Flutter apps/packages:** route extras and query parameters, API base URL configuration, Dio interceptors, auth/session storage, response models, state transitions, background telemetry, map/location permissions, and passenger/driver contract parity.
- **Go gateway/core/realtime:** route registration, proxy paths, middleware order, auth claims, ownership checks, DTO/domain mapping, request limits, timeouts, retries, WebSockets, Redis/RabbitMQ behavior, and generic error responses.
- **Rides/fare/wallet/document flows:** idempotency, state transitions, money units, transaction boundaries, participant visibility, upload authorization, and auditability.
- **Admin web app:** API contract changes, session handling, authorization boundaries, server-side loading, CSV/report exposure, and browser security.
- **Docker/config/dependencies:** environment names, public bindings, service startup order, health checks, migrations, lock/manifest consistency, and accidental secret exposure.

Never call a server response “working” solely because it returned HTTP 2xx. Verify parsing, state propagation, rendering, retries, and consumer expectations.

## Reference files

- [git_operations.md](references/git_operations.md): target resolution, diff retrieval, root/merge/range handling, and safe fallbacks.
- [impact_detection.md](references/impact_detection.md): consumer tracing and breaking-change analysis for Flutter, Go, TypeScript, and infrastructure.
- [output_format.md](references/output_format.md): concise finding and verdict format.
