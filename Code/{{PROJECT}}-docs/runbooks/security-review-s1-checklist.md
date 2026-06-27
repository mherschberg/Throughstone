# S1 Checklist — Security Sweep

Use this checklist when running **S1 — Security Sweep** from
[`security-review.md`](security-review.md). S1 is a lightweight recurring review for security
drift, advisories, stale accepted risks, and security-sensitive changes since the last review.

S1 is not the S0 baseline and not the S2 audit. It assumes the project has some recorded intended
posture, usually in the Security & Threat Model architecture doc, and asks whether the current
system still matches it. If S1 finds missing baseline guardrails, create or run an S0 Security
Baseline STEP. If it finds broad uncertainty, high-risk design change, or a review surface too
large for a sweep, create an S2 Security Audit STEP.

## Outcome Values

Use exactly one outcome for every applicable row:

| Outcome | Meaning | Minimum record |
|---------|---------|----------------|
| No issue | Reviewed and no material drift, alert, or action was found. | Evidence, date, reviewer. |
| Fixed during review | A small, low-risk issue was corrected as part of the sweep. | Change made, evidence, commit/PR if available. |
| Follow-up STEP | Non-trivial work is needed outside the sweep. | STEP/issue ref, owner, severity/priority. |
| Accepted Risk | The team accepts the risk or a longer deferral. | `registries/risks.yml` ref, owner, reason, revisit trigger. |
| Escalate S0 | Baseline guardrails are missing, stale, or invalidated. | Security Baseline STEP/issue or reason for immediate S0. |
| Escalate S2 | A deeper audit is needed. | Security Audit STEP/issue and reason. |
| Incident | Active compromise, serious exposure, malicious dependency, or urgent exploited vulnerability. | Switch to `incident-postmortem.md`; record incident ref. |
| N/A | The item does not apply to the project in its current shape. | Reason, and trigger that would make it applicable if useful. |

## Evidence Rules

- Prefer durable evidence: architecture docs, ADRs, changed files, scanner reports, dependency
  alert dashboards, package audit output, vendor advisories, issue/STEP links, release notes,
  configuration snapshots, or command output summaries.
- Do not paste secrets, private tokens, customer data, exploit payloads, sensitive logs, or
  detailed infrastructure internals into the report. Reference the secure system that holds them.
- When checking public advisory sources, record what source was checked and the date. Use current
  primary or authoritative sources where possible, such as ecosystem advisories, vendor security
  bulletins, OSV/GitHub advisories, and CISA KEV for exploited vulnerabilities.
- Use `registries/risks.yml` for meaningful accepted risks, stale deferrals, or monitoring items.
  The S1 report may summarize the decision, but the durable risk/debt index lives there.
- Update the Security & Threat Model architecture doc only if reality changed. Do not edit it just
  to record that the sweep happened.

## Sweep Checklist

Copy the rows into the S1 report, then add project-specific rows for any security-relevant
technology, surface, or integration. Keep non-applicable rows in the report as `N/A` when their
absence is a useful future signal.

| Area | Review item | Outcome | Evidence / notes | Follow-up STEP / issue | Risk ref |
|------|-------------|---------|------------------|------------------------|----------|
| Setup | Identify the trigger for this S1: cadence, check-in gate, advisory, release, incident follow-up, or security-sensitive change. | TBD | TBD | TBD | TBD |
| Setup | Read the last S1/S2 report and `registries/security-reviews.yml`; record elapsed time, commits, rough size change, and previous carry-forward items. | TBD | TBD | TBD | TBD |
| Setup | Define scope: repos, services, packages, deployed environments, public surfaces, data stores, AI/tool-calling surfaces, and intentionally skipped areas. | TBD | TBD | TBD | TBD |
| Setup | Confirm the Security & Threat Model, architecture overview, environments, interface contracts, and data model docs still identify the security-relevant surfaces being swept. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Review open dependency/security alerts across all package ecosystems and repos in scope. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Run or review the project's dependency vulnerability audit process from `dependency-supply-chain.md`; record command/report evidence or why unavailable. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Check relevant exploited-vulnerability sources, including CISA KEV where applicable, for technologies, frameworks, runtimes, databases, CI/CD, hosting, and appliances in use. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Review vendor, cloud, framework, and platform security advisories for externally hosted services or managed components the project depends on. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Review container, base image, package artifact, or IaC/cloud posture alerts if the project ships or deploys those artifacts. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Review SAST/security-lint findings and confirm any deferrals are tracked as risks or follow-up work. | TBD | TBD | TBD | TBD |
| Dependency and security alerts | Check CI/CD and supply-chain surfaces for new risky actions/images/scripts, unpinned third-party components, overly broad tokens, or alerting regressions. | TBD | TBD | TBD | TBD |
| Accepted risks | Review every open or monitoring security item in `registries/risks.yml`; decide whether the revisit trigger fired, severity changed, owner changed, or source artifact drifted. | TBD | TBD | TBD | TBD |
| Accepted risks | Close mitigated risks, update stale risks, and create follow-up STEPs for risks whose trigger fired or whose severity is no longer acceptable. | TBD | TBD | TBD | TBD |
| Auth/AuthZ | Compare current authentication flows, session/token behavior, password or identity-provider assumptions, and MFA/admin-access expectations with the architecture docs. | TBD | TBD | TBD | TBD |
| Auth/AuthZ | Review authorization boundaries: roles, permissions, ownership checks, tenant isolation, admin paths, service-to-service access, and bypass/error paths. | TBD | TBD | TBD | TBD |
| Auth/AuthZ | Review recent auth/AuthZ changes since the last S1/S2 for missing tests, changed trust assumptions, or undocumented access paths. | TBD | TBD | TBD | TBD |
| Data exposure | Confirm collected, stored, displayed, logged, exported, imported, and shared data still matches the Security & Threat Model and Data Model docs. | TBD | TBD | TBD | TBD |
| Data exposure | Review public APIs, downloads, reports, search, previews, webhooks, notifications, and analytics for accidental exposure of sensitive or cross-tenant data. | TBD | TBD | TBD | TBD |
| Data exposure | Review backup, retention, deletion, and environment-copy assumptions for sensitive data drift. | TBD | TBD | TBD | TBD |
| Secrets and config | Check for secrets or credentials in tracked files, examples, logs, generated artifacts, prompts, test fixtures, and documentation. | TBD | TBD | TBD | TBD |
| Secrets and config | Confirm secret storage, CI secrets, environment variables, local `.env` handling, and rotation assumptions still match docs and deployment reality. | TBD | TBD | TBD | TBD |
| Secrets and config | If a suspected secret exposure is found, stop normal S1 handling and use `secrets-rotation.md` or the incident runbook as appropriate. | TBD | TBD | TBD | TBD |
| Logging and monitoring | Confirm security-relevant events are still logged or observable where expected: auth failures, admin actions, permission denials, data exports, deploys, config changes, and dependency alerts. | TBD | TBD | TBD | TBD |
| Logging and monitoring | Check logs, errors, traces, analytics, and support tooling for sensitive data leakage or over-retention. | TBD | TBD | TBD | TBD |
| Rate limiting and abuse controls | Confirm rate limits, quotas, abuse detection, lockouts, replay controls, or equivalent controls still cover public or high-cost surfaces. | TBD | TBD | TBD | TBD |
| File uploads and user content | If uploads/imports/user content exist, review validation, size/type limits, malware scanning if required, storage permissions, direct-object access, processing isolation, and content-serving headers. | TBD | TBD | TBD | TBD |
| External integrations | Review external integrations, OAuth scopes, API keys, webhooks, callback URLs, payment or regulated workflows, email/SMS providers, and third-party data sharing for drift. | TBD | TBD | TBD | TBD |
| External integrations | Confirm integration failures, retries, signature verification, idempotency, and webhook authorization still match interface-contract and threat-model assumptions. | TBD | TBD | TBD | TBD |
| Infrastructure and deployment | Review public exposure, network boundaries, TLS/domain settings, CORS/security headers, environment separation, least-privilege service credentials, and deployment rollback assumptions for drift. | TBD | TBD | TBD | TBD |
| Infrastructure and deployment | Confirm production-like environments and admin/operations surfaces have not gained undocumented access paths or unmanaged manual changes. | TBD | TBD | TBD | TBD |
| AI and tool-calling | If AI, agents, tool-calling, retrieval, user-provided prompts, or model outputs exist, review tool permissions, data boundaries, prompt-injection exposure, output handling, auditability, and kill-switch/escalation assumptions. | TBD | TBD | TBD | TBD |
| AI and tool-calling | Confirm AI/tool-calling changes since the last review are reflected in architecture docs only if they changed actual security posture. | TBD | TBD | TBD | TBD |
| Documentation | Update the Security & Threat Model, architecture docs, ADRs, or interface contracts only when the implemented system or intended posture changed. | TBD | TBD | TBD | TBD |
| Follow-up | File follow-up STEPs for non-trivial fixes; do not hide implementation work inside the review STEP. | TBD | TBD | TBD | TBD |
| Follow-up | Decide whether S0 or S2 is due based on missing baseline guardrails, release/production milestones, high-risk changes, broad uncertainty, or incident follow-up. | TBD | TBD | TBD | TBD |
| Completion | Update the S1 report, `registries/security-reviews.yml`, and any affected `registries/risks.yml` rows. | TBD | TBD | TBD | TBD |

## S1 Completion Criteria

An S1 sweep is complete when:

- The report records the trigger, scope, intentionally skipped areas, reviewer, reviewed commit,
  change markers, and next recommended review date or trigger.
- Each applicable checklist row has one of the allowed outcomes and enough evidence for a future
  reviewer to understand the decision.
- Relevant dependency/security alerts, exploited-advisory sources, and vendor/platform advisories
  were checked or explicitly marked unavailable/out of scope.
- Open security risks in `registries/risks.yml` were reviewed, updated, closed, or promoted to
  follow-up STEPs.
- Small low-risk fixes made during the sweep are recorded with evidence.
- Non-trivial work is tracked as follow-up STEPs or issues, not hidden inside the review.
- Any active compromise, serious exposure, malicious dependency, or urgent exploited vulnerability
  was moved to incident handling instead of being treated as normal review work.
- `registries/security-reviews.yml` points to the completed S1 report.
