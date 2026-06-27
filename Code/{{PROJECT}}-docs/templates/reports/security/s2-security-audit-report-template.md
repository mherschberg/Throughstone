# S2 Security Audit Report - {{PROJECT}}

**Review level:** S2 - Security Audit
**Review date:** YYYY-MM-DD
**Trigger:** Public launch / sensitive production use / high-risk cadence / incident follow-up /
major security-posture change / customer-regulatory need / other: TBD
**Reviewer(s):** TBD
**Report owner:** TBD
**Reviewed commit:** TBD
**STEP / issue:** TBD

## Summary

- **Overall result:** Pass / follow-up required / accepted risk / specialist review needed /
  S0 needed / incident escalated
- **Highest severity finding:** Critical / High / Medium / Low / Info / None
- **Highest-risk module:** TBD
- **Modules reviewed:** TBD
- **Modules deferred or N/A:** TBD
- **Follow-up STEPs created:** TBD
- **Accepted risks updated:** TBD
- **Specialist reviews required:** TBD
- **Security & Threat Model changed:** Yes / No
- **Next review trigger/date:** TBD

## Scope

### Included

- Repositories: TBD
- Services/apps/packages: TBD
- Web surfaces: TBD
- APIs and service interfaces: TBD
- Mobile clients, if any: TBD
- AI/agent/RAG/tool-calling surfaces, if any: TBD
- Data stores and sensitive data classes: TBD
- Deployed environments and cloud/IaC: TBD
- CI/CD, release, artifact, and supply-chain systems: TBD
- External integrations and vendors: TBD
- Security tooling/dashboards reviewed: TBD
- Process/governance areas reviewed: TBD

### Intentionally Skipped

| Area skipped | Reason | Owner | Revisit trigger |
|--------------|--------|-------|-----------------|
| TBD | TBD | TBD | TBD |

## Change Markers

| Marker | Value | Notes |
|--------|-------|-------|
| Previous S2 report | TBD | Blank if this is the first S2. |
| Previous S1 report | TBD | Optional context if more recent than S2. |
| Previous S0 report | TBD | Note whether baseline is current or follow-up is needed. |
| Elapsed time since previous S2 | TBD | TBD |
| Reviewed commit | TBD | Match `registries/security-reviews.yml`. |
| Commits since previous S2 | TBD | Leave blank with note if impractical. |
| Rough SLOC or equivalent size | TBD | Optional cheap snapshot. |
| Rough SLOC delta since previous S2 | TBD | Leave blank with note if impractical. |
| Major architecture/product/security changes | TBD | Auth/AuthZ, data, deployment, AI, integrations, public surfaces. |
| Release/production/customer milestone changes | TBD | TBD |
| Incidents or serious advisories since last review | TBD | TBD |

## Framework Versions And Sources

Record the versions or dates checked for each selected external framework. Remove rows that are
clearly not relevant only after recording the module disposition below.

| Framework / source | URL | Version / date checked | Used for | Notes |
|--------------------|-----|------------------------|----------|-------|
| OWASP Top 10 | <https://owasp.org/www-project-top-ten/> | 2025 or current at audit time | Web awareness baseline | Not sufficient by itself for S2. |
| OWASP API Security Top 10 | <https://owasp.org/www-project-api-security/> | 2023 or current at audit time | API module | TBD |
| OWASP ASVS | <https://owasp.org/www-project-application-security-verification-standard/> | TBD | App verification depth | Target level: L1 / L2 / L3 / N/A |
| OWASP SAMM | <https://owasp.org/www-project-samm/> | TBD | Process maturity | TBD |
| CWE Top 25 | <https://cwe.mitre.org/top25/> | TBD | Secure implementation review | TBD |
| CIS Controls | <https://www.cisecurity.org/controls/v8-1> | v8.1 or current at audit time | Operational posture | TBD |
| NIST SSDF / SP 800-218 | <https://csrc.nist.gov/pubs/sp/800/218/final> | SSDF v1.1 or current at audit time | Secure-development practices | TBD |
| NIST Cybersecurity Framework | <https://www.nist.gov/cyberframework> | 2.0 or current at audit time | Governance/risk posture | TBD |
| SLSA | <https://slsa.dev/> | v1.2 or current at audit time | Build provenance / supply chain | Target level: TBD |
| OpenSSF Scorecard | <https://scorecard.dev/> | TBD | Repository hygiene | TBD |
| CycloneDX / SPDX SBOM | <https://cyclonedx.org/> / <https://spdx.dev/> | TBD | SBOM format/tooling | TBD |
| OWASP Mobile Top 10 | <https://owasp.org/www-project-mobile-top-10/> | 2024 or current at audit time | Mobile module | TBD |
| OWASP LLM / GenAI guidance | <https://genai.owasp.org/> | TBD | AI/agent/RAG/tool-calling module | TBD |

## Inputs Reviewed

Use these sections for the major inputs that shaped the audit. Add or remove sections as needed
for the project. Each section should be brief but complete enough that a future reviewer can tell
what was checked, what was skipped, and why the evidence was sufficient.

### Security Review Ledger

**Reviewed:** Yes / No

**Evidence / source:** `registries/security-reviews.yml`

**Notes:** Last S0/S1/S2, cadence, stale markers, and carry-forward items: TBD

### Prior Security Reports

**Reviewed:** Yes / No

**Evidence / source:** S0/S1/S2 reports: TBD

**Notes:** Open findings, stale baseline items, previous accepted risks, and repeated gaps: TBD

### Risk Register

**Reviewed:** Yes / No

**Evidence / source:** `registries/risks.yml`

**Notes:** Open and monitoring security risks reviewed, closed, updated, escalated, or promoted:
TBD

### Security & Threat Model

**Reviewed:** Yes / No

**Evidence / source:** TBD

**Notes:** Assets, trust boundaries, threats, mitigations, deferrals, AuthN/AuthZ posture,
secrets posture, and web-risk posture still match reality: TBD

### Related Architecture Docs And Interface Contracts

**Reviewed:** Yes / No

**Evidence / source:** Architecture overview / data model / environments / infrastructure /
observability / interface contracts / conditional security docs: TBD

**Notes:** Security-sensitive drift only; note docs intentionally skipped: TBD

### Implementation, Tests, And Tooling

**Reviewed:** Yes / No

**Evidence / source:** Code, tests, SAST/security lint, dependency scans, container/IaC scans,
fuzz/property tests, manual review notes, or scanner dashboards: TBD

**Notes:** Applicable tools, unavailable reports, deferrals, false positives, and stale
findings: TBD

### Deployment, Operations, And Cloud/IaC

**Reviewed:** Yes / No / N/A

**Evidence / source:** Environments, cloud consoles, IaC, deployment workflows, logging,
monitoring, backups, incident runbook, or operations docs: TBD

**Notes:** Production posture, environment separation, manual drift, alerting, and recovery:
TBD

### Secure Development Process

**Reviewed:** Yes / No / N/A

**Evidence / source:** Planning docs, code review rules, release runbook, dependency runbook,
security training/process, vulnerability response process, and governance docs: TBD

**Notes:** SSDF/SAMM/NIST CSF-style process findings: TBD

## Module Selection

Use dispositions and outcomes exactly as defined by
[`runbooks/security-review-s2-checklist.md`](../../../runbooks/security-review-s2-checklist.md).

| Module | Applies? | Disposition | Reason | Depth / framework target | Owner | Follow-up STEP / issue |
|--------|----------|-------------|--------|--------------------------|-------|------------------------|
| Scoping and audit setup | Yes | In scope | Every S2 needs scope and evidence rules. | Required | TBD | TBD |
| Prior reviews, baseline, and risk ledger | Yes | In scope | S2 builds on S0/S1 and open risks. | Required | TBD | TBD |
| Threat model and architecture posture | Yes | In scope | Every S2 checks intended posture against reality. | Required | TBD | TBD |
| Web application security | Yes / No | TBD | TBD | OWASP Top 10; ASVS L1/L2/L3 | TBD | TBD |
| API and service security | Yes / No | TBD | TBD | OWASP API Top 10; ASVS API controls | TBD | TBD |
| AuthN, AuthZ, session, and tenant isolation | Yes / No | TBD | TBD | ASVS identity/session/access controls | TBD | TBD |
| Data protection and privacy-supporting controls | Yes / No | TBD | TBD | ASVS data controls; NIST CSF; project privacy docs | TBD | TBD |
| Secure implementation and CWE review | Yes / No | TBD | TBD | CWE Top 25; language/framework standards | TBD | TBD |
| Mobile application security | Yes / No | TBD | TBD | OWASP Mobile Top 10; MASVS if adopted | TBD | TBD |
| LLM, AI, agent, RAG, and tool-calling security | Yes / No | TBD | TBD | OWASP LLM/GenAI guidance | TBD | TBD |
| Dependency, SBOM, and vulnerability response | Yes / No | TBD | TBD | Dependency runbook; SBOM; OSV/GitHub/vendor advisories | TBD | TBD |
| CI/CD, provenance, and software supply chain | Yes / No | TBD | TBD | SLSA; OpenSSF Scorecard; SSDF | TBD | TBD |
| Infrastructure, cloud, and operational posture | Yes / No | TBD | TBD | CIS Controls v8.1; CIS Benchmarks where adopted; NIST CSF | TBD | TBD |
| Secure SDLC, governance, and maturity | Yes / No | TBD | TBD | NIST SSDF; OWASP SAMM; NIST CSF 2.0 | TBD | TBD |
| Specialist penetration test or external assurance | Yes / No | TBD | TBD | Project-specific | TBD | TBD |

## Checklist Outcomes

Use this compact index for selected modules. Put detailed evidence in the module sections below;
do not paste the wide checklist table here unless the project needs row-level traceability.

| Module | Outcome | Highest severity | Finding count | Follow-up STEP / issue | Risk ref |
|--------|---------|------------------|---------------|------------------------|----------|
| Scoping and audit setup | TBD | TBD | TBD | TBD | TBD |
| Prior reviews, baseline, and risk ledger | TBD | TBD | TBD | TBD | TBD |
| Threat model and architecture posture | TBD | TBD | TBD | TBD | TBD |
| Web application security | TBD | TBD | TBD | TBD | TBD |
| API and service security | TBD | TBD | TBD | TBD | TBD |
| AuthN, AuthZ, session, and tenant isolation | TBD | TBD | TBD | TBD | TBD |
| Data protection and privacy-supporting controls | TBD | TBD | TBD | TBD | TBD |
| Secure implementation and CWE review | TBD | TBD | TBD | TBD | TBD |
| Mobile application security | TBD | TBD | TBD | TBD | TBD |
| LLM, AI, agent, RAG, and tool-calling security | TBD | TBD | TBD | TBD | TBD |
| Dependency, SBOM, and vulnerability response | TBD | TBD | TBD | TBD | TBD |
| CI/CD, provenance, and software supply chain | TBD | TBD | TBD | TBD | TBD |
| Infrastructure, cloud, and operational posture | TBD | TBD | TBD | TBD | TBD |
| Secure SDLC, governance, and maturity | TBD | TBD | TBD | TBD | TBD |
| Specialist penetration test or external assurance | TBD | TBD | TBD | TBD | TBD |

## Module Review Details

### Scoping And Audit Setup

**Reviewed:** Yes / No

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Trigger, scope, intentionally skipped areas, module selection, framework versions,
reviewed commit, and change markers recorded: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Prior Reviews, Baseline, And Risk Ledger

**Reviewed:** Yes / No

**Outcome:** TBD

**Severity:** TBD

**Evidence:** S0/S1/S2 reports, ledger, current S0 status, open security risks, stale
deferrals, and previous carry-forward items reviewed: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Threat Model And Architecture Posture

**Reviewed:** Yes / No

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Security & Threat Model, related architecture docs, interface contracts,
implementation, and deployed reality compared: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Web Application Security

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** OWASP Top 10 coverage, ASVS target level, browser/web session surfaces, public and
admin UI, input/output handling, CSRF, CORS/security headers, uploads/content, and rate limits:
TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### API And Service Security

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** API inventory, object/function-level authorization, schema validation, mass
assignment, rate limits, versioning, webhooks, service-to-service calls, replay protection,
signatures, idempotency, and failure behavior: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### AuthN, AuthZ, Session, And Tenant Isolation

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Account lifecycle, MFA/admin requirements, identity provider posture, password
policy if applicable, session/token lifetime, refresh/revocation, recovery flows, roles,
permissions, tenant boundaries, admin paths, support impersonation, service accounts, policy
tests, and bypass/error paths: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Data Protection And Privacy-Supporting Controls

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Sensitive data inventory, classification, minimization, storage, encryption, key
management, backups, retention, deletion/export paths, logs, analytics, test data, environment
copies, and regulated/payment/customer-contractual control needs: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Secure Implementation And CWE Review

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Applicable CWE Top 25 classes, language/framework security standards, dangerous
APIs, framework defaults, negative tests, fuzz/property tests where useful, and security test
coverage: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Mobile Application Security

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Platform permissions, local storage, secrets, certificate/TLS handling,
auth/session flows, deep links, IPC, WebViews, update paths, backend APIs, logging, and
reverse-engineering assumptions: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### LLM, AI, Agent, RAG, And Tool-Calling Security

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Prompt injection, tool permissions, least privilege, data boundaries, retrieval
poisoning, context leakage, output handling, human approval gates, model-mediated decisions,
auditability, abuse/cost limits, kill switches, model/provider/data dependencies, model supply
chain, evaluations, and red-team prompts: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Dependency, SBOM, And Vulnerability Response

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Dependency/supply-chain audit, package ecosystems, containers, OS/base images,
plugins, models/datasets, vendor advisories, SBOM generation, vulnerability response ownership,
patch SLAs, false-positive handling, license/redistribution constraints, and disclosure
expectations: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### CI/CD, Provenance, And Software Supply Chain

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** CI workflow trust boundaries, token permissions, branch protections, third-party
actions/images/scripts, secrets exposure, artifact signing, provenance attestations, build
isolation, release approvals, rollback integrity, SLSA target/current gaps, and OpenSSF
Scorecard-style repo hygiene: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Infrastructure, Cloud, And Operational Posture

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Asset inventory, identity/access, network exposure, TLS/DNS/CDN, storage/database
access, backups/restore, logging/monitoring, alerting, vulnerability management, secure
configuration, secrets, environment separation, incident readiness, IaC/cloud scans, CIS
Benchmarks or provider best practices where adopted, manual console drift, admin break-glass,
and production change controls: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Secure SDLC, Governance, And Maturity

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** NIST SSDF and/or OWASP SAMM-style security requirements, design review, secure
coding, code review, security testing, vulnerability response, release gates, training,
third-party risk, improvement process, governance/risk ownership, policy, customer assurance,
and detect/respond/recover readiness: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

### Specialist Penetration Test Or External Assurance

**Reviewed:** Yes / No / N/A

**Outcome:** TBD

**Severity:** TBD

**Evidence:** Need for external penetration test, cloud review, mobile review, AI red team,
privacy/compliance review, customer/enterprise assurance, payment/regulated review, or other
specialist assessment: TBD

**Notes:** TBD

**Findings / fixes:** TBD

**Follow-up STEP / issue:** TBD

**Risk ref:** TBD

## Findings

### Fixed During Audit

| Finding | Module | Severity | Change made | Evidence |
|---------|--------|----------|-------------|----------|
| TBD | TBD | Low / Medium / High / Critical / Info | TBD | TBD |

### Follow-Up Required

| Finding | Module | Severity | Owner | Follow-up STEP / issue | Target date / trigger | Risk ref |
|---------|--------|----------|-------|------------------------|-----------------------|----------|
| TBD | TBD | Low / Medium / High / Critical / Info | TBD | TBD | TBD | TBD |

### Accepted Risks Or Deferrals

| Risk ref | Module | Severity | Decision | Reason | Owner | Revisit trigger |
|----------|--------|----------|----------|--------|-------|-----------------|
| TBD | TBD | TBD | Accepted Risk / Deferred / Monitoring | TBD | TBD | TBD |

### Specialist Reviews

| Area | Reason | Owner | Target date / trigger | Vendor/process if known | Follow-up STEP / issue |
|------|--------|-------|-----------------------|-------------------------|------------------------|
| TBD | TBD | TBD | TBD | TBD | TBD |

### Escalations

| Escalation | Reason | STEP / incident ref | Owner |
|------------|--------|---------------------|-------|
| S0 / S1 / Incident / None | TBD | TBD | TBD |

## Documentation Updates

| Artifact | Changed? | Reason | Evidence |
|----------|----------|--------|----------|
| Security & Threat Model architecture doc | Yes / No | TBD | TBD |
| Other architecture docs / ADRs / interface contracts | Yes / No | TBD | TBD |
| `registries/risks.yml` | Yes / No | TBD | TBD |
| `registries/security-reviews.yml` | Yes | Points to this report. | TBD |
| Runbooks or project security procedures | Yes / No | TBD | TBD |

## Ledger Update

After completing the audit, update `registries/security-reviews.yml` for `S2`:

```yaml
S2:
  last_run:
    date: YYYY-MM-DD
    report: reports/security/YYYY-MM-DD-s2-security-audit-report.md
    reviewed_commit: TBD
    sloc_at_review: TBD
    commits_since_previous: TBD
    sloc_delta_since_previous: TBD
    notes: TBD
  next_due: TBD
```

## Reviewer Notes

TBD
