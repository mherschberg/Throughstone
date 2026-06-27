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

Use these sections for the major inputs that shaped the sweep. Add or remove sections as needed
for the project. Each section should be brief but complete enough that a future reviewer can tell
what was checked, what was skipped, and why the evidence was sufficient.

### Security Review Ledger

**Reviewed:** Yes / No

**Evidence / source:** `registries/security-reviews.yml`

**Notes:** Last S0/S1/S2, cadence, stale markers, and carry-forward items: TBD

### Risk Register

**Reviewed:** Yes / No

**Evidence / source:** `registries/risks.yml`

**Notes:** Open and monitoring security risks reviewed, closed, updated, or promoted: TBD

### Security & Threat Model

**Reviewed:** Yes / No

**Evidence / source:** TBD

**Notes:** Intended posture, trust boundaries, threat assumptions, sensitive data, and controls
still match reality. Update only if reality changed: TBD

### Related Architecture Docs

**Reviewed:** Yes / No

**Evidence / source:** Architecture overview / environments / data model / interface contracts:
TBD

**Notes:** Security-sensitive drift only; note docs intentionally skipped: TBD

### Dependency And Security Alert Dashboards

**Reviewed:** Yes / No

**Evidence / source:** Git host, bot, package manager, vendor, scanner, or other dashboard: TBD

**Notes:** Open alerts, stale alerts, false positives, suppressed items, and ownership: TBD

### Dependency Audit Process

**Reviewed:** Yes / No

**Evidence / source:** `runbooks/dependency-supply-chain.md`; command/report or reason unavailable:
TBD

**Notes:** Package ecosystems covered and intentionally skipped: TBD

### Advisory Sources

**Reviewed:** Yes / No

**Evidence / source:** See **Advisory Sources Checked** below.

**Notes:** Include exploited-advisory, ecosystem, vendor, cloud, framework, and platform sources
that apply to the project: TBD

### Security Tooling Reports

**Reviewed:** Yes / No

**Evidence / source:** SAST, security lint, container/image scan, IaC/cloud posture, SBOM, or
other tooling reports: TBD

**Notes:** Applicable tools, unavailable reports, deferrals, and stale findings: TBD

### Recent Changes Since Last Review

**Reviewed:** Yes / No

**Evidence / source:** Commits, PRs, releases, deployment history, roadmap, or STEP reports: TBD

**Notes:** Focus on security-sensitive changes: auth/AuthZ, data, deployment, AI/tool-calling,
integrations, public surfaces, dependencies, and incident follow-up: TBD

## Advisory Sources Checked

Use the starter sources from
[`runbooks/security-review-s1-checklist.md`](../../../runbooks/security-review-s1-checklist.md),
then add or remove rows based on the project stack. Keep rows for skipped-but-relevant sources so
the reason is explicit.

| Source | URL / dashboard | Applies? | Date checked | Result | Follow-up STEP / issue |
|--------|-----------------|----------|--------------|--------|------------------------|
| CISA Known Exploited Vulnerabilities catalog | <https://www.cisa.gov/known-exploited-vulnerabilities-catalog> | Yes / No | YYYY-MM-DD | TBD | TBD |
| OSV.dev / OSV-Scanner | <https://osv.dev/> | Yes / No | YYYY-MM-DD | TBD | TBD |
| GitHub Advisory Database / GitHub security alerts | <https://github.com/advisories> | Yes / No | YYYY-MM-DD | TBD | TBD |
| NVD | <https://nvd.nist.gov/> | Yes / No | YYYY-MM-DD | TBD | TBD |
| CVE.org | <https://www.cve.org/> | Yes / No | YYYY-MM-DD | TBD | TBD |
| Project dependency/security alert dashboards | TBD | Yes / No | YYYY-MM-DD | TBD | TBD |
| Vendor/cloud/framework/platform advisories | TBD | Yes / No | YYYY-MM-DD | TBD | TBD |
| Stack-specific source: Go Vulnerability Database | <https://pkg.go.dev/vuln> | Yes / No | YYYY-MM-DD | TBD | TBD |
| Stack-specific source: RustSec Advisory Database | <https://rustsec.org/advisories/> | Yes / No | YYYY-MM-DD | TBD | TBD |
| Stack-specific source: Kubernetes official CVE feed | <https://kubernetes.io/docs/reference/issues-security/official-cve-feed/> | Yes / No | YYYY-MM-DD | TBD | TBD |
| Stack-specific source: OS/base image tracker | TBD | Yes / No | YYYY-MM-DD | TBD | TBD |
| Other project-specific source | TBD | Yes / No | YYYY-MM-DD | TBD | TBD |

## Checklist Outcomes

Use outcomes exactly as defined by
[`runbooks/security-review-s1-checklist.md`](../../../runbooks/security-review-s1-checklist.md):
`No issue`, `Fixed during review`, `Follow-up STEP`, `Accepted Risk`, `Escalate S0`,
`Escalate S2`, `Incident`, or `N/A`.

Use this table as the compact index. Put detailed evidence in the area sections below.

| Area | Outcome | Finding count | Follow-up STEP / issue | Risk ref |
|------|---------|---------------|------------------------|----------|
| Setup | TBD | TBD | TBD | TBD |
| Dependency and security alerts | TBD | TBD | TBD | TBD |
| Accepted risks | TBD | TBD | TBD | TBD |
| Auth/AuthZ | TBD | TBD | TBD | TBD |
| Data exposure | TBD | TBD | TBD | TBD |
| Secrets and config | TBD | TBD | TBD | TBD |
| Logging, monitoring, rate limiting, and uploads | TBD | TBD | TBD | TBD |
| External integrations | TBD | TBD | TBD | TBD |
| Infrastructure and deployment | TBD | TBD | TBD | TBD |
| AI and tool-calling | TBD | TBD | TBD | TBD |
| Documentation and follow-up | TBD | TBD | TBD | TBD |

## Area Review Details

Use these sections for evidence and judgment. Add project-specific subsections when the sweep
finds a security-relevant area that is not covered by the starter structure.

### Setup

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Trigger, previous reviews, scope, intentionally skipped areas, reviewed commit, and
change markers recorded: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Dependency And Security Alerts

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Dependency alerts, vulnerability audits, exploited advisories, vendor advisories,
SAST/security lint, artifact/IaC alerts, and CI supply-chain surfaces reviewed: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Accepted Risks

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Open and monitoring security risks reviewed; stale, mitigated, or triggered risks
updated: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Auth/AuthZ

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Authentication, authorization, session/token, tenant, admin, and service-to-service
boundaries still match the architecture docs and recent changes: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Data Exposure

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Sensitive data collection, storage, logs, exports, APIs, notifications, backups,
and cross-tenant boundaries reviewed for drift: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Secrets And Config

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Secrets, config, CI secret exposure, local env handling, generated artifacts, docs,
logs, and rotation assumptions reviewed: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Logging, Monitoring, Rate Limiting, And Uploads

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Security logging, sensitive log leakage, rate limiting/abuse controls, and
upload/user-content handling reviewed where applicable: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### External Integrations

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** OAuth scopes, API keys, webhooks, callbacks, payment/regulated workflows,
third-party sharing, retries, and signature checks reviewed: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Infrastructure And Deployment

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Public exposure, network boundaries, TLS/domains, CORS/security headers,
environment separation, least privilege, and rollback assumptions reviewed: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### AI And Tool-Calling

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Evidence:** AI/agent/tool-calling, retrieval, user prompts, model outputs, data boundaries,
tool permissions, and auditability reviewed if present: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Documentation And Follow-Up

**Reviewed:** Yes / No

**Outcome:** TBD

**Evidence:** Security docs updated only if reality changed; non-trivial fixes filed as STEPs;
S0/S2/incident escalation considered: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

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
