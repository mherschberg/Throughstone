# S1 Security Sweep — {{PROJECT}}

**Review level:** S1 — Security Sweep
**Review date:** YYYY-MM-DD
**Trigger:** Cadence / check-in gate / advisory / release / incident follow-up /
security-sensitive change / other: TBD
**Reviewer(s):** TBD
**Report owner:** TBD
**Reviewed commit:** TBD
**STEP / issue:** TBD

## Summary

- **Overall result:** No material findings / fixed during review / follow-up required /
  S0 needed / S2 needed / incident escalated
- **Highest severity finding:** TBD
- **Most important drift:** TBD
- **Follow-up STEPs created:** TBD
- **Accepted risks updated:** TBD
- **Security & Threat Model changed:** Yes / No
- **Next review trigger/date:** TBD

## Scope

### Included

- Repositories: TBD
- Services/apps/packages: TBD
- Deployed environments: TBD
- Package ecosystems: TBD
- Public/API/admin surfaces: TBD
- Data stores and sensitive data classes: TBD
- External integrations: TBD
- AI/tool-calling surfaces, if any: TBD
- Security tooling/dashboards reviewed: TBD

### Intentionally skipped

| Area skipped | Reason | Owner | Revisit trigger |
|--------------|--------|-------|-----------------|
| TBD | TBD | TBD | TBD |

## Change Markers

| Marker | Value | Notes |
|--------|-------|-------|
| Previous S1 report | TBD | Blank if this is the first S1. |
| Previous S2 report | TBD | Optional context if more recent than S1. |
| Elapsed time since previous S1/S2 | TBD | TBD |
| Reviewed commit | TBD | Match `registries/security-reviews.yml`. |
| Commits since previous S1 | TBD | Leave blank with note if impractical. |
| Rough SLOC or equivalent size | TBD | Optional cheap snapshot. |
| Rough SLOC delta since previous S1 | TBD | Leave blank with note if impractical. |
| Major architecture/product/security changes | TBD | Auth/AuthZ, data, deployment, AI, integrations, public surfaces. |
| Release/production milestone changes | TBD | TBD |

## Inputs Reviewed

| Input | Reviewed? | Evidence / source | Notes |
|-------|-----------|-------------------|-------|
| `registries/security-reviews.yml` | TBD | TBD | Last S0/S1/S2 and cadence. |
| `registries/risks.yml` | TBD | TBD | Open and monitoring security risks. |
| Security & Threat Model architecture doc | TBD | TBD | Update only if reality changed. |
| Architecture overview / environments / data model / interface contracts | TBD | TBD | Security-sensitive drift only. |
| Dependency/security alert dashboards | TBD | TBD | Git host, bot, package manager, vendor, or scanner. |
| Dependency audit process from `runbooks/dependency-supply-chain.md` | TBD | TBD | Command/report or reason unavailable. |
| Exploited-advisory sources, including CISA KEV where applicable | TBD | TBD | Date checked and relevant technology searched. |
| Vendor/cloud/framework advisories | TBD | TBD | Managed services and platforms in use. |
| SAST/security-lint/container/IaC/security tooling reports | TBD | TBD | Applicable tools only. |
| Recent commits/PRs/releases since last review | TBD | TBD | Focus on security-sensitive changes. |

## Checklist Outcomes

Use outcomes exactly as defined by
[`runbooks/security-review-s1-checklist.md`](../../../runbooks/security-review-s1-checklist.md):
`No issue`, `Fixed during review`, `Follow-up STEP`, `Accepted Risk`, `Escalate S0`,
`Escalate S2`, `Incident`, or `N/A`.

| Area | Review item | Outcome | Evidence / notes | Follow-up STEP / issue | Risk ref |
|------|-------------|---------|------------------|------------------------|----------|
| Setup | Trigger, previous reviews, scope, and intentionally skipped areas recorded. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Dependency alerts, vulnerability audits, exploited advisories, vendor advisories, SAST/security lint, artifact/IaC alerts, and CI supply-chain surfaces reviewed. | TBD | TBD | TBD | TBD |
| Accepted risks | Open and monitoring security risks reviewed; stale, mitigated, or triggered risks updated. | TBD | TBD | TBD | TBD |
| Auth/AuthZ | Authentication, authorization, session/token, tenant, admin, and service-to-service boundaries still match the architecture docs and recent changes. | TBD | TBD | TBD | TBD |
| Data exposure | Sensitive data collection, storage, logs, exports, APIs, notifications, backups, and cross-tenant boundaries reviewed for drift. | TBD | TBD | TBD | TBD |
| Secrets and config | Secrets, config, CI secret exposure, local env handling, generated artifacts, docs, logs, and rotation assumptions reviewed. | TBD | TBD | TBD | TBD |
| Logging, monitoring, rate limiting, and uploads | Security logging, sensitive log leakage, rate limiting/abuse controls, and upload/user-content handling reviewed where applicable. | TBD | TBD | TBD | TBD |
| External integrations | OAuth scopes, API keys, webhooks, callbacks, payment/regulated workflows, third-party sharing, retries, and signature checks reviewed. | TBD | TBD | TBD | TBD |
| Infrastructure and deployment | Public exposure, network boundaries, TLS/domains, CORS/security headers, environment separation, least privilege, and rollback assumptions reviewed. | TBD | TBD | TBD | TBD |
| AI and tool-calling | AI/agent/tool-calling, retrieval, user prompts, model outputs, data boundaries, tool permissions, and auditability reviewed if present. | TBD | TBD | TBD | TBD |
| Documentation and follow-up | Security docs updated only if reality changed; non-trivial fixes filed as STEPs; S0/S2/incident escalation considered. | TBD | TBD | TBD | TBD |

## Findings

### Fixed During Review

| Finding | Severity | Change made | Evidence |
|---------|----------|-------------|----------|
| TBD | Low / Medium / High / Critical | TBD | TBD |

### Follow-Up Required

| Finding | Severity | Owner | Follow-up STEP / issue | Target date / trigger | Risk ref |
|---------|----------|-------|------------------------|-----------------------|----------|
| TBD | Low / Medium / High / Critical | TBD | TBD | TBD | TBD |

### Accepted Risks Or Deferrals

| Risk ref | Decision | Reason | Owner | Revisit trigger |
|----------|----------|--------|-------|-----------------|
| TBD | Accepted Risk / Deferred / Monitoring | TBD | TBD | TBD |

### Escalations

| Escalation | Reason | STEP / incident ref | Owner |
|------------|--------|---------------------|-------|
| S0 / S2 / Incident / None | TBD | TBD | TBD |

## Documentation Updates

| Artifact | Changed? | Reason | Evidence |
|----------|----------|--------|----------|
| Security & Threat Model architecture doc | Yes / No | TBD | TBD |
| Other architecture docs / ADRs / interface contracts | Yes / No | TBD | TBD |
| `registries/risks.yml` | Yes / No | TBD | TBD |
| `registries/security-reviews.yml` | Yes | Points to this report. | TBD |

## Ledger Update

After completing the sweep, update `registries/security-reviews.yml` for `S1`:

```yaml
S1:
  last_run:
    date: YYYY-MM-DD
    report: reports/security/YYYY-MM-DD-s1-security-sweep.md
    reviewed_commit: TBD
    sloc_at_review: TBD
    commits_since_previous: TBD
    sloc_delta_since_previous: TBD
    notes: TBD
  next_due: TBD
```

## Reviewer Notes

TBD
