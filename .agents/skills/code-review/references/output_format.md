# Code Review Output

Lead with the resolved target and verdict. Group findings by severity unless the user requests file grouping.

```markdown
# Code Review

Target: `<commit | range | staged | HEAD>`
Scope: `<all files or path list>`

## Findings

### [Critical] Short issue title

- Location: [`path/to/file.go:42`](/absolute/path/to/file.go:42)
- Confidence: High
- Issue: What is incorrect or unsafe.
- Evidence: The changed control flow or consumer trace that proves it.
- Impact: Concrete user, service, data, availability, or contract consequence.
- Suggestion: Smallest complete remediation and regression test.

### [Major] ...

...

## Highlights

- Improvements that materially reduce risk or improve compatibility.

## Limitations

- Checks not run, unavailable devices/services, sampled files, or unverified deployment assumptions.

## Verdict

`REQUEST_CHANGES` | `COMMENT` | `APPROVE`

Decision rationale: summarize the highest-risk evidence and why the verdict follows.
```

Do not include empty findings sections if there are no findings. Do include a concise `Highlights` section when the patch has meaningful strengths. Report exact commands and results in `Limitations` or verification notes; never imply that an end-to-end flow ran when only static analysis or unit tests ran.

## Finding rules

- One root cause per finding.
- Prefer the narrowest location that demonstrates the issue.
- Explain why existing validation or middleware does or does not contain the risk.
- Do not report style-only issues as Major or Critical.
- Do not label a speculative concern as a confirmed vulnerability; use Medium/Low confidence and state the required verification.
