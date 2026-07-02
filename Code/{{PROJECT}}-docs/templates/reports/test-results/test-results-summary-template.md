# {{PROJECT}} — Test Results Summary

**Run date:** {{YYYY-MM-DD}}
**Report path:** `reports/test-results/{{YYYY-MM-DD}}-{{scope}}-test-results.md`
**Context:** {{STEP-{{N}} / release candidate / incident follow-up / security review / check-in}}
**Overall result:** {{passed / failed / partially passed / skipped}}
**Run by:** {{person / agent / CI workflow}}
**Run source:** {{local command / CI run URL / PR URL / release job / other}}
**Environment:** {{local / CI / staging / production-like / other}}
**Architecture source:** `architecture/12-test-strategy.md`

## Scope

| Repo | Branch | Commit | Suites / gates covered | Notes |
|------|--------|--------|------------------------|-------|
| {{repo}} | `{{branch}}` | `{{sha}}` | {{unit / integration / e2e / lint / typecheck / build / coverage}} | {{single-repo or multi-repo notes}} |

For a single-repo project, keep one row. For a multi-repo project, add one row for each repo whose
code, contracts, tests, or quality gates were part of this run.

## Result Summary

| Repo / suite | Command or CI job | Result | Counts | Notes |
|--------------|-------------------|--------|--------|-------|
| {{repo / suite}} | `{{command-or-job}}` | {{passed / failed / skipped}} | {{passed/failed/skipped counts}} | {{important failures, skips, flakes, retries, duration if useful}} |

## Coverage Summary

| Repo / surface | Language / tool | Result | Threshold / gate | Full artifact |
|----------------|-----------------|--------|------------------|---------------|
| {{repo / surface}} | {{language}} / {{tool}} | {{coverage result or N/A}} | {{passed / failed / not gated}} | {{CI artifact URL / coverage-service URL / local ignored path / N/A}} |

Coverage is a visibility and trend signal, not proof of quality. Summarize what matters: critical
paths covered, important gaps, and whether the configured gate passed.

## Notable Findings

| Finding | Impact | Action |
|---------|--------|--------|
| {{failure / coverage gap / flaky test / skipped suite / none}} | {{risk or user impact}} | {{fixed / follow-up STEP or issue / accepted risk / none}} |

## Follow-Up

| Item | Owner | Target |
|------|-------|--------|
| {{STEP-N / issue / ADR / risk / none}} | {{owner}} | {{when or trigger}} |

## Additional Notes

{{Any extra context that does not fit the structured fields: unusual environment conditions,
temporary workarounds, known CI instability, manual verification notes, or why this run matters.}}

## Summary

{{Briefly state whether the tested scope is healthy, what changed since the last meaningful run if
known, and any remaining risk the reader should understand.}}
