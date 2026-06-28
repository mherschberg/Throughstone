# {{PROJECT}} — STEP-{{NNNN}} Check-In Report

**Date:** {{YYYY-MM-DD}}
**Check-in STEP:** STEP-{{N}}
**Report path:** `reports/{{YYYY-MM-DD}}-step-{{NNNN}}-check-in-report.md`
**Reviewed commit(s):** {{repo@sha list}}
**Runbook:** `runbooks/check-in.md`

## Drift

| Area | Reviewed | Finding | Action |
|------|----------|---------|--------|
| Architecture docs vs. code | {{docs/repos}} | {{none / summary}} | {{doc fixed / ADR written / bug STEP filed}} |
| Code vs. still-correct docs | {{docs/repos}} | {{none / summary}} | {{bug STEP filed / fixed here}} |
| Repo READMEs | {{repos}} | {{none / summary}} | {{updated / follow-up}} |
| Interface contracts | {{artifacts}} | {{none / summary}} | {{updated / follow-up}} |
| Docstrings | {{areas}} | {{none / summary}} | {{updated / follow-up}} |

## Conditional Coverage

| Conditional session | Current disposition | Evidence | Follow-up |
|---------------------|---------------------|----------|-----------|
| {{templates/architecture-sessions/conditional-*.md}} | {{Included / Deferred / N/A / Needs follow-up}} | {{doc/STEP/report}} | {{STEP-N / None}} |

## Risks And Debt

| Risk/debt item | Status before | Decision | Action |
|----------------|---------------|----------|--------|
| {{RISK-0000 / description}} | {{open / monitoring / ...}} | {{still valid / close / promote}} | {{registry update / follow-up STEP / none}} |

## Security Review Gate

| Level | Current status | Due? | Action |
|-------|----------------|------|--------|
| S0 Security Baseline | {{latest / none}} | {{yes/no}} | {{STEP-N / none}} |
| S1 Security Sweep | {{latest / none}} | {{yes/no}} | {{STEP-N / none}} |
| S2 Security Audit | {{latest / none}} | {{yes/no}} | {{STEP-N / none}} |

## Tests

| Repo / suite | Command | Result | Notes |
|--------------|---------|--------|-------|
| {{repo}} | `{{command}}` | {{passed/failed/skipped}} | {{counts, coverage, failures}} |

## Carry-Forward

| Item | Type | Owner | Next action |
|------|------|-------|-------------|
| {{STEP-N / issue / risk}} | {{bug / conditional / risk / docs}} | {{owner}} | {{what happens next}} |

## Summary

{{Brief statement of project health, material changes made during the check-in, and when the
next check-in should be considered.}}
