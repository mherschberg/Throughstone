# S2 Checklist - Security Audit

Use this checklist when running **S2 - Security Audit** from
[`security-review.md`](security-review.md). S2 is a deeper structured review against the
external security frameworks and threat areas that apply to the project. It is strongly
recommended before public launch, before sensitive production use, after major security-posture
changes, after serious incidents, and on the chosen cadence for high-risk production systems.

S2 is not "run every checklist." It is an applicability-driven audit. Select the modules that
match the project's architecture, data, users, deployment model, and risk. Record why modules
were included, deferred, or marked not applicable.

## How S2 Differs From S0 And S1

- **S0** checks whether the project has baseline guardrails: repository hygiene, CI/security
  tooling, secret scanning, dependency alerts, artifact scanning, and operational readiness.
- **S1** checks drift since the last review: advisories, stale risks, changed surfaces, and
  security-sensitive implementation changes.
- **S2** evaluates whether the system's design, implementation, supply chain, operations, and
  secure-development practices stand up against the applicable frameworks.

OWASP Top 10 is useful, but it is not enough for S2. Treat it as an awareness baseline for web
applications. Use ASVS, API Security Top 10, Mobile Top 10, LLM/GenAI guidance, CWE, SSDF,
SAMM, CIS, SLSA, SBOM, cloud posture, and operational modules where they match the system.

## Outcome Values

Use exactly one outcome for every applicable checklist row:

| Outcome | Meaning | Minimum record |
|---------|---------|----------------|
| Pass | Reviewed and no material gap was found for this audit scope. | Evidence, date, reviewer, framework/control reference where useful. |
| Partial | Some controls are present, but coverage is incomplete or unverified. | Gap, impact, owner, follow-up STEP/issue or risk ref. |
| Gap | A material weakness, missing control, or untested security assumption was found. | Finding, severity, affected scope, owner, required fix or accepted-risk decision. |
| Fixed during audit | A small, low-risk issue was corrected during the audit. | Change made, evidence, commit/PR if available. |
| Follow-up STEP | Non-trivial work is needed outside the audit. | STEP/issue ref, owner, severity, target trigger/date. |
| Accepted Risk | The team accepts the risk or a longer deferral. | `registries/risks.yml` ref, owner, reason, revisit trigger. |
| Specialist review | The area needs an external, domain-specific, legal, compliance, privacy, cloud, AI, mobile, or penetration-testing review. | Scope, owner, trigger/date, vendor or process if known. |
| Incident | Active compromise, serious exposure, malicious dependency, or urgent exploited vulnerability. | Switch to `incident-postmortem.md`; record incident ref. |
| N/A | The item does not apply to the project in its current shape. | Reason and trigger that would make it applicable if useful. |

## Severity Values

Use these severity labels for findings. Projects may add CVSS, EPSS, exploitability, business
impact, or customer impact fields, but keep this minimum vocabulary stable:

| Severity | Use when |
|----------|----------|
| Critical | Likely or confirmed compromise, unauthenticated privileged access, broad sensitive-data exposure, exploitable supply-chain compromise, payment/regulatory emergency, or no credible mitigation for a high-impact path. |
| High | Plausible exploitation of sensitive data, tenant boundaries, admin functions, production secrets, build/release integrity, payment/regulated flows, or high-value AI/tool actions. |
| Medium | Meaningful weakness with compensating controls, limited blast radius, or exploitation requiring unusual preconditions. |
| Low | Localized hardening issue, defense-in-depth gap, missing documentation, or low-impact configuration weakness. |
| Info | Useful observation, future trigger, or documentation/process improvement without current material risk. |

## Evidence Rules

- Prefer durable evidence: architecture docs, ADRs, interface contracts, threat model sections,
  test results, scanner reports, audit logs, access-control matrices, deployment/IaC settings,
  cloud dashboards, CI workflow files, package metadata, SBOMs, provenance attestations, and
  command output summaries.
- Do not paste secrets, private tokens, customer data, exploit payloads, sensitive logs, or
  detailed infrastructure internals into the report. Reference the secure system that holds
  them.
- When using external standards, record the version/date checked because security frameworks
  change. Prefer current primary sources.
- Use `registries/risks.yml` for accepted security risks, meaningful deferrals, and monitoring
  items. The S2 report may summarize the decision, but the durable risk/debt index lives there.
- Update architecture docs only if reality or intended posture changed. Do not edit them merely
  to say that the audit happened.
- If the audit reveals active compromise, serious exposure, a malicious dependency, or urgent
  exploited vulnerability, stop normal S2 handling and move to incident response.

## Framework Reference Set

Verify current versions when the audit runs. This scaffold starts from the following public
frameworks and guidance. Use only the references that match the project and add project-specific
standards when needed.

- **OWASP Top 10 2025** (<https://owasp.org/www-project-top-ten/>) is an awareness baseline
  for common web application risk classes. It is not a full audit standard by itself.
- **OWASP API Security Top 10 2023** (<https://owasp.org/www-project-api-security/>) applies
  to API-heavy systems, public APIs, partner APIs, and internal service APIs with meaningful
  trust boundaries.
- **OWASP ASVS** (<https://owasp.org/www-project-application-security-verification-standard/>)
  is the more rigorous application-security verification checklist. Choose Level 1, 2, or 3
  based on project risk.
- **OWASP SAMM** (<https://owasp.org/www-project-samm/>) reviews secure-development maturity
  across governance, design, implementation, verification, and operations.
- **CWE Top 25** (<https://cwe.mitre.org/top25/>) helps target implementation review, tests,
  and secure-code hardening at common weakness classes.
- **CIS Controls v8.1** (<https://www.cisecurity.org/controls/v8-1>) covers operational
  security hygiene such as inventory, access control, secure configuration, logging, recovery,
  and vulnerability management.
- **NIST SSDF v1.1 / SP 800-218** (<https://csrc.nist.gov/pubs/sp/800/218/final>) checks secure
  software development practices: prepare, protect software, produce well-secured software, and
  respond to vulnerabilities.
- **NIST Cybersecurity Framework 2.0** (<https://www.nist.gov/cyberframework>) is useful for
  broader governance, risk, identify/protect/detect/respond/recover posture.
- **SLSA v1.2** (<https://slsa.dev/>) covers build integrity, provenance, source/build
  isolation, and supply-chain assurance.
- **OpenSSF Scorecard** (<https://scorecard.dev/>) gives repository and dependency hygiene
  signals for open-source or shared-source repos.
- **SBOM formats and tooling** such as CycloneDX (<https://cyclonedx.org/>) and SPDX
  (<https://spdx.dev/>) support component inventory for distribution, incident response,
  vulnerability response, and enterprise/customer assurance.
- **OWASP Mobile Top 10 2024** (<https://owasp.org/www-project-mobile-top-10/>) applies to
  native or hybrid mobile apps, mobile SDKs, mobile API clients, and app-store distributed
  clients.
- **OWASP LLM / GenAI guidance** (<https://genai.owasp.org/>) applies to LLM, agent, RAG,
  tool-calling, prompt-injection, model-mediated decision, and model supply-chain surfaces.

## Module Selection

Start every S2 with scoping, then choose modules. Record each selected module in the report's
module-selection table with one disposition: **In scope**, **Deferred**, **Specialist review**,
or **N/A**. Use **Deferred** only when the module applies but is intentionally moved to later
work with an owner and trigger. Use **Specialist review** when normal project review is not
enough and the area needs external/domain expertise. Use **N/A** when the module does not apply
to the current project shape.

Every S2 should include scoping and audit setup, prior reviews/baseline/risk-ledger review, and
threat-model/architecture-posture review. Add the remaining modules only when they match the
project:

- Web application security: public/admin web app, browser client, server-rendered UI, SPA, or
  web session surface. Typical references: OWASP Top 10 and ASVS.
- API and service security: public, partner, mobile, internal, GraphQL, RPC, webhook, or
  service-to-service APIs. Typical references: OWASP API Security Top 10 and ASVS API controls.
- AuthN, AuthZ, session, and tenant isolation: accounts, roles, admins, tenants, service
  accounts, or privileged workflows.
- Data protection and privacy-supporting controls: sensitive, personal, regulated, payment,
  health, financial, confidential, or customer data.
- Secure implementation and CWE review: custom code handles input, parsing, files, auth,
  crypto, concurrency, serialization, memory, commands, or queries.
- Mobile application security: native/hybrid mobile apps, mobile SDKs, mobile local storage,
  mobile auth, or app-store distribution.
- LLM, AI, agent, RAG, and tool-calling security: LLMs, agents, retrieval, prompts, tools,
  model-mediated decisions, embeddings, fine-tuning, or generated code/content.
- Dependency, SBOM, and vulnerability response: third-party packages, containers, images,
  plugins, AI models, datasets, or redistributable artifacts.
- CI/CD, provenance, and software supply chain: automated build, release, packages, containers,
  deploy pipelines, outside contributors, or distributed artifacts.
- Infrastructure, cloud, and operational posture: hosted environments, cloud/IaC, Kubernetes,
  databases, queues, CDN, object storage, DNS, admin consoles, or production operations.
- Secure SDLC, governance, and maturity: production systems, teams, compliance expectations,
  enterprise customers, high-risk cadence, or security program review.
- Specialist penetration test or external assurance: public launch, high-value target,
  regulatory/customer requirement, payments, regulated data, critical infrastructure, or
  untrusted multi-tenant system.

## S2 Checklist

Copy applicable rows into the S2 report. Add project-specific rows when the system has a
security-relevant surface not covered by the starter structure.

| Module | Review item | Outcome | Severity | Evidence / notes | Follow-up STEP / issue | Risk ref |
|--------|-------------|---------|----------|------------------|------------------------|----------|
| Scoping and audit setup | Identify trigger: public launch, sensitive production use, high-risk cadence, incident follow-up, major architecture/security change, customer/regulatory need, or explicit request. | TBD | TBD | TBD | TBD | TBD |
| Scoping and audit setup | Define scope: repos, services, apps, APIs, mobile clients, AI systems, data stores, environments, CI/CD, artifacts, cloud resources, and intentionally skipped areas. | TBD | TBD | TBD | TBD | TBD |
| Scoping and audit setup | Select applicable modules and record disposition, depth target, owner, and skipped/deferred rationale. | TBD | TBD | TBD | TBD | TBD |
| Scoping and audit setup | Record external framework versions or dates checked for each selected module. | TBD | TBD | TBD | TBD | TBD |
| Prior reviews, baseline, and risk ledger | Read the last S0/S1/S2 reports and `registries/security-reviews.yml`; record elapsed time, commits, rough size change, and carry-forward items. | TBD | TBD | TBD | TBD | TBD |
| Prior reviews, baseline, and risk ledger | Run S0 or create a follow-up S0 STEP if baseline guardrails are missing, stale, or invalidated by repo/CI/hosting/deployment/ownership changes. | TBD | TBD | TBD | TBD | TBD |
| Prior reviews, baseline, and risk ledger | Review all open/monitoring security risks in `registries/risks.yml`; close, update, escalate, or create follow-up STEPs where triggers fired. | TBD | TBD | TBD | TBD | TBD |
| Threat model and architecture posture | Confirm the Security & Threat Model still identifies assets, trust boundaries, threats, mitigations, deferrals, AuthN/AuthZ posture, secrets posture, and web-risk posture. | TBD | TBD | TBD | TBD | TBD |
| Threat model and architecture posture | Compare architecture docs and interface contracts to implementation and deployed reality for security-relevant drift. | TBD | TBD | TBD | TBD | TBD |
| Threat model and architecture posture | Re-check highest-risk abuse cases and failure modes: privilege escalation, data exposure, tenant escape, replay, tampering, availability/cost abuse, insider/admin misuse, and unsafe automation. | TBD | TBD | TBD | TBD | TBD |
| Web application security | Review OWASP Top 10 coverage and map each applicable category to controls, tests, framework protections, or accepted risks. | TBD | TBD | TBD | TBD | TBD |
| Web application security | Choose an ASVS target level and review applicable controls for validation, output encoding, CSRF, sessions, access control, error handling, file handling, SSRF, security headers, and browser/client risks. | TBD | TBD | TBD | TBD | TBD |
| Web application security | Review public and admin web surfaces for unauthenticated access, authorization bypasses, injection, XSS, CSRF, clickjacking, CORS/header issues, upload/content risks, and rate limits. | TBD | TBD | TBD | TBD | TBD |
| API and service security | Review API inventory, authentication, authorization, object/function-level access control, schema validation, mass assignment, rate limits, pagination, filtering, error handling, and versioning. | TBD | TBD | TBD | TBD | TBD |
| API and service security | Review webhooks, callbacks, service-to-service calls, GraphQL/RPC/event contracts, replay protection, signatures, idempotency, and failure/retry behavior. | TBD | TBD | TBD | TBD | TBD |
| AuthN, AuthZ, session, and tenant isolation | Review account lifecycle, MFA/admin requirements, password or identity-provider posture, session/token lifetime, refresh/revocation, cookie flags, device/session management, and recovery flows. | TBD | TBD | TBD | TBD | TBD |
| AuthN, AuthZ, session, and tenant isolation | Review role/permission model, object ownership, tenant boundaries, admin paths, support impersonation, service accounts, policy tests, deny-by-default behavior, and bypass/error paths. | TBD | TBD | TBD | TBD | TBD |
| Data protection and privacy-supporting controls | Review sensitive data inventory, classification, minimization, storage, encryption, key management, backups, retention, deletion/export paths, logs, analytics, test data, and environment copies. | TBD | TBD | TBD | TBD | TBD |
| Data protection and privacy-supporting controls | Review regulated, payment, health, financial, confidential, or customer contractual controls; create specialist privacy/compliance follow-up where legal obligations exceed technical audit scope. | TBD | TBD | TBD | TBD | TBD |
| Secure implementation and CWE review | Review code paths against applicable CWE Top 25 classes: injection, XSS, out-of-bounds/memory, deserialization, path traversal, SSRF, auth/authorization errors, hardcoded credentials, race conditions, weak crypto, and improper error handling. | TBD | TBD | TBD | TBD | TBD |
| Secure implementation and CWE review | Review security tests, negative tests, fuzz/property tests where useful, secure coding standards, framework defaults, dependency wrapper code, and dangerous APIs. | TBD | TBD | TBD | TBD | TBD |
| Mobile application security | If mobile applies, review platform permissions, local storage, secrets, certificate/TLS handling, auth/session flows, deep links, IPC, WebViews, update paths, backend APIs, logging, and reverse-engineering assumptions. | TBD | TBD | TBD | TBD | TBD |
| LLM, AI, agent, RAG, and tool-calling security | If AI applies, review prompt-injection exposure, tool permissions, least privilege, data boundaries, retrieval poisoning, context leakage, output handling, human approval gates, model-mediated decisions, auditability, abuse/cost limits, and kill switches. | TBD | TBD | TBD | TBD | TBD |
| LLM, AI, agent, RAG, and tool-calling security | Review AI model/provider/data dependencies, model supply chain, evaluation coverage, red-team prompts, unsafe generated content/code, and failure handling. | TBD | TBD | TBD | TBD | TBD |
| Dependency, SBOM, and vulnerability response | Run or review the dependency/supply-chain audit from `dependency-supply-chain.md`; include package ecosystems, containers, OS/base images, plugins, models/datasets, and vendor advisories. | TBD | TBD | TBD | TBD | TBD |
| Dependency, SBOM, and vulnerability response | Review SBOM generation, vulnerability response ownership, false-positive handling, patch SLAs, license/redistribution constraints, and customer/security disclosure expectations. | TBD | TBD | TBD | TBD | TBD |
| CI/CD, provenance, and software supply chain | Review CI workflow trust boundaries, token permissions, branch protections, third-party actions/images/scripts, secrets exposure, artifact signing, provenance attestations, build isolation, release approvals, and rollback integrity. | TBD | TBD | TBD | TBD | TBD |
| CI/CD, provenance, and software supply chain | Select a SLSA target where artifacts are distributed or customer/enterprise assurance is needed; record current level/gaps and follow-up. | TBD | TBD | TBD | TBD | TBD |
| Infrastructure, cloud, and operational posture | Review asset inventory, identity/access, network exposure, TLS/DNS/CDN, storage/database access, backups/restore, logging/monitoring, alerting, vulnerability management, secure configuration, secrets, environment separation, and incident readiness. | TBD | TBD | TBD | TBD | TBD |
| Infrastructure, cloud, and operational posture | Review IaC/cloud posture scanner results, CIS Benchmarks or provider best practices where adopted, manual console drift, admin break-glass paths, and production change controls. | TBD | TBD | TBD | TBD | TBD |
| Secure SDLC, governance, and maturity | Review NIST SSDF and/or OWASP SAMM-style practices: security requirements, design review, secure coding, code review, testing, vulnerability response, release gates, training, third-party risk, and continuous improvement. | TBD | TBD | TBD | TBD | TBD |
| Secure SDLC, governance, and maturity | Review NIST CSF-style governance/risk posture where needed: asset ownership, risk appetite, policy, vendor/customer assurance, detect/respond/recover readiness, and executive/customer reporting needs. | TBD | TBD | TBD | TBD | TBD |
| Specialist penetration test or external assurance | Decide whether public launch, sensitive data, payments, regulated workflows, enterprise customer requirements, or multi-tenant/high-value exposure require external penetration testing, cloud review, mobile review, AI red team, or compliance review. | TBD | TBD | TBD | TBD | TBD |
| Completion | Record findings, fixes, accepted risks, specialist referrals, documentation updates, follow-up STEPs, ledger update, and next recommended review date/trigger. | TBD | TBD | TBD | TBD | TBD |

## Completion Criteria

An S2 audit is complete when:

- The report records trigger, scope, intentionally skipped areas, reviewer, reviewed commit,
  change markers, selected modules, module dispositions, framework versions/dates checked, and
  next recommended review date or trigger.
- Every selected module has enough evidence for a future reviewer to understand what was
  checked, what was not checked, and why the depth was appropriate.
- Applicable findings have severity, affected scope, evidence, owner, required fix or accepted
  risk, target trigger/date, and follow-up STEP/issue when work remains.
- Open security risks in `registries/risks.yml` were reviewed, updated, closed, or promoted to
  follow-up STEPs.
- S0 was run or scheduled if the baseline was missing, stale, or invalidated.
- Non-trivial fixes are tracked as follow-up STEPs or issues, not hidden inside the audit.
- Any active compromise, serious exposure, malicious dependency, or urgent exploited
  vulnerability was moved to incident handling instead of being treated as normal audit work.
- Architecture docs, ADRs, interface contracts, and runbooks were updated only where the
  implemented system or intended posture changed.
- `registries/security-reviews.yml` points to the completed S2 report.
