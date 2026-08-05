# Security Audit Report Format

```markdown
# Code Security Audit

## Executive summary

- Scope: `<paths, commit/worktree, services>`
- Level: `L1 | L2 | L3`
- Focus: `<domains>`
- Overall posture: `<risk summary>`
- Findings: `<Critical>/<High>/<Medium>/<Low>/<Info>`

## Methodology and limitations

Describe reconnaissance, code/data-flow tracing, OWASP source roles, tests/scanners run, excluded areas, unavailable services, and assumptions. State when exact OWASP identifiers were not verified.

## Findings

### [High] Short title

- Location: [`server/path/file.go:42`](/absolute/path/server/path/file.go:42)
- Domain: Authentication / Authorization / Injection / ...
- OWASP mapping: `<verified ASVS/API/CWE/WSTG mapping or Not mapped>`
- Confidence: High / Medium / Low
- Data flow: source -> control -> sink
- Evidence: concrete code and call-path evidence
- Impact: affected actor, data, integrity, or availability consequence
- Existing controls: relevant middleware, validation, deployment, or tests
- Remediation: smallest complete fix
- Verification: test/scanner result or required follow-up

## Domain observations

Summarize checked controls and meaningful gaps by domain, without repeating findings.

## Remediation roadmap

1. Immediate Critical/High fixes and compensating controls.
2. Current-sprint Medium fixes and regression coverage.
3. Defense-in-depth Low/Info improvements and recurring tooling.

## Residual risk

State what remains unknown or depends on deployment, credentials, external providers, devices, or runtime testing.
```

Do not call the result “fully secure.” Separate confirmed vulnerabilities, probable issues, recommendations, and untested areas. Link to the narrowest source line that demonstrates each finding and do not include secret values in evidence.
