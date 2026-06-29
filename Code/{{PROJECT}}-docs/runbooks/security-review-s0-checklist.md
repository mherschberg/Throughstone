# S0 Checklist — Security Baseline

Use this checklist when running **S0 — Security Baseline** from
[`security-review.md`](security-review.md). S0 is strongly recommended before the first
release, but it is not a release gate unless the project chooses to make it one. Earlier use is
optional.

S0 checks whether the project has the guardrails security depends on: external tooling,
repository and CI hygiene, secrets handling, dependency and advisory setup, and baseline
operational practices. It is not a substitute for an S1 sweep of current drift or an S2 audit
of application design and implementation.

## Status Values

Use exactly one status for every applicable row:

| Status | Meaning | Minimum record |
|--------|---------|----------------|
| Done | The guardrail exists and has been verified for the current project. | Decision date, owner, evidence. |
| Planned | The team agrees this guardrail is needed, but implementation is tracked for later. | Decision date, owner, target date or trigger, follow-up STEP/issue if available. |
| Deferred | The team is not doing it now because timing, scope, or maturity does not justify it yet. | Decision date, owner, reason, revisit trigger. |
| Accepted Risk | The team accepts the risk of not doing it, or of doing it only partially. | Decision date, owner, reason, revisit trigger, risk ref unless fully captured elsewhere. |
| N/A | The item does not apply to this project in its current shape. | Decision date, owner, reason, revisit trigger if it could become applicable. |

## Evidence Rules

- Prefer durable evidence: settings pages, policy files, workflow files, scanner reports,
  command output snapshots, ADRs, archived STEP plan/execution notes, vendor dashboards,
  tickets, or issue URLs.
- Do not paste secrets, private tokens, customer data, or sensitive infrastructure details into
  the report. Reference the secure system that holds them.
- Use `registries/risks.yml` for accepted security risks and meaningful deferrals. The S0 report
  may summarize the decision, but the durable risk/debt index lives there. When an item is listed
  in the risk register, put the exact `RISK-0000` ID in that row's `Risk ref` cell so the report
  cross-references the specific entry.
- If a tool is not configured because the project is pre-release, small, internal, or still a
  prototype, record that as `Deferred` or `N/A` with a concrete trigger. Do not leave blank rows.

## Baseline Decision Table

Copy the rows into the S0 report, then add project-specific guardrails as needed. Keep
non-applicable rows in the report as `N/A` unless the same decision is clearly captured in a
broader row.

| Area | Baseline item | Status | Decision date | Owner | Reason / evidence | Revisit trigger | Risk ref |
|------|---------------|--------|---------------|-------|-------------------|-----------------|----------|
| Setup | Read the last S0 report and `registries/security-reviews.yml`; record elapsed time, commits, rough size change, previous baseline decisions, and carry-forward items. | TBD | YYYY-MM-DD | TBD | TBD | TBD | TBD |
| Release posture | First-release security baseline decision recorded: S0 done now, planned before release, deferred, or accepted as risk. | TBD | YYYY-MM-DD | TBD | TBD | Before first release; before public launch; when release scope changes. | TBD |
| Release posture | Release runbook has a security-aware pre-flight: tests green, config/secrets in place, rollback plan, and production verification. | TBD | YYYY-MM-DD | TBD | `runbooks/release-deploy.md`; project-specific release docs or CI evidence. | Before first release; after deployment process changes. | TBD |
| Ownership | Security owners or accountable maintainers are identified for code, infrastructure, secrets, and incident response. | TBD | YYYY-MM-DD | TBD | Owner list, team rota, repository maintainers, or operations doc. | Team ownership change; production handoff. | TBD |
| Ownership | Access review cadence exists for repos, CI/CD, package registries, cloud accounts, production systems, and secret stores. | TBD | YYYY-MM-DD | TBD | Access review policy, calendar, ticket, or checklist. | Before first production use; after team membership changes. | TBD |
| Repository hygiene | Default branch protection or equivalent merge control is configured for protected branches. | TBD | YYYY-MM-DD | TBD | Branch protection settings, ruleset, or host policy reference. | Before first shared release; after repo host changes. | TBD |
| Repository hygiene | Required review/status checks are configured for security-relevant branches. | TBD | YYYY-MM-DD | TBD | Branch rules, required checks, or merge policy. | Before first release; after CI changes. | TBD |
| Repository hygiene | Security policy or vulnerability-reporting path exists if the project has external users, customers, or public source. | TBD | YYYY-MM-DD | TBD | `SECURITY.md`, support route, private disclosure process, or `N/A` reason. | Before public source; before external users. | TBD |
| Repository hygiene | OpenSSF Scorecard-style repo hygiene has been reviewed or intentionally deferred. | TBD | YYYY-MM-DD | TBD | Scorecard report, manual review, or deferral reason. | Before public launch; after major workflow/repo changes. | TBD |
| Repository hygiene | Release provenance expectations are recorded: tags, signed releases or commits if required, changelog/release notes, artifact source. | TBD | YYYY-MM-DD | TBD | ADR, release runbook, repo settings, signing policy, or `N/A` reason. | Before distributing artifacts; before public launch. | TBD |
| CI hygiene | CI workflows run from reviewed repository code and avoid dangerous pull-request contexts for untrusted code. | TBD | YYYY-MM-DD | TBD | Workflow review, CI config paths, or host policy reference. | After adding/changing workflows; before accepting outside PRs. | TBD |
| CI hygiene | CI token permissions are least-privilege by default; write permissions are scoped to jobs that need them. | TBD | YYYY-MM-DD | TBD | Workflow `permissions`, repo/org CI settings, or vendor policy. | After workflow changes; before release automation. | TBD |
| CI hygiene | Third-party CI actions, build images, and setup scripts are pinned or otherwise controlled according to project policy. | TBD | YYYY-MM-DD | TBD | Workflow files, pinning policy, digest/tag evidence, or accepted-risk ref. | After adding actions/images; before public release. | TBD |
| CI hygiene | CI secrets are only exposed to trusted jobs/environments, not arbitrary forks or unreviewed scripts. | TBD | YYYY-MM-DD | TBD | CI environment rules, protected environments, workflow conditions. | Before outside contributions; after CI/provider changes. | TBD |
| CI hygiene | Build and test workflows cover the release branches and fail closed for required checks. | TBD | YYYY-MM-DD | TBD | CI status checks, workflow files, branch protection settings. | Before first release; after build-system changes. | TBD |
| Secrets handling | Secrets are stored in a secret manager or CI secret store, not in tracked files. | TBD | YYYY-MM-DD | TBD | Secret store reference, `.gitignore`, `.env.example`, configuration docs. | Before deploying shared environments; after adding integrations. | TBD |
| Secrets handling | Secret scanning is enabled or run for repository history and ongoing pushes. | TBD | YYYY-MM-DD | TBD | Git host secret scanning, gitleaks/trufflehog report, pre-commit hook, or deferral reason. | Before first release; before making repo public; after import/migration. | TBD |
| Secrets handling | A suspected-secret-exposure response path exists and points to the secrets rotation runbook. | TBD | YYYY-MM-DD | TBD | `runbooks/secrets-rotation.md`; incident response docs; owner. | Before production secrets exist; after adding secret classes. | TBD |
| Secrets handling | Local development configuration uses ignored secret files and committed examples/templates only. | TBD | YYYY-MM-DD | TBD | `.gitignore`, `.env.example`, onboarding docs, template files. | After adding config/secrets; before onboarding contributors. | TBD |
| Dependency alerts | Dependency vulnerability alerting is enabled or scheduled for every package ecosystem in use. | TBD | YYYY-MM-DD | TBD | Dependabot, Renovate, OSV-Scanner, ecosystem audit command, or vendor dashboard. | Before first release; after adding an ecosystem/repo. | TBD |
| Dependency alerts | Dependency update policy exists for security patches, regular updates, and major upgrades. | TBD | YYYY-MM-DD | TBD | ADR, runbook, bot config, check-in cadence, or issue labels. | Before first release; after painful/stale dependency drift. | TBD |
| Dependency alerts | Lockfiles or equivalent reproducible dependency controls are committed and checked. | TBD | YYYY-MM-DD | TBD | Lockfiles, package manager config, CI install mode, or `N/A` reason. | After adding package managers; before release. | TBD |
| Dependency alerts | License compatibility scanning or manual review is planned for projects that redistribute code or artifacts. | TBD | YYYY-MM-DD | TBD | License scanner, dependency policy, manual review evidence, or `N/A` reason. | Before public distribution; before commercial redistribution. | TBD |
| Static analysis | Security-oriented linting or SAST is configured where useful for the project stack. | TBD | YYYY-MM-DD | TBD | CodeQL, Semgrep, Bandit, Brakeman, gosec, cargo-audit-related checks, compiler/linter rules, or deferral reason. | Before first release; after stack changes. | TBD |
| Static analysis | Findings from SAST/security lint are triaged, with real deferrals recorded as risks or tracked work. | TBD | YYYY-MM-DD | TBD | Scanner report, issue list, STEP, or risk refs. | Each S1 sweep; before release. | TBD |
| Artifacts | Container/image/package scanning is configured if the project ships deployable artifacts. | TBD | YYYY-MM-DD | TBD | Trivy, Grype, registry scan, package scan, or `N/A` reason. | Before shipping images/packages; after base image changes. | TBD |
| Artifacts | Release artifacts are built reproducibly enough to trace source commit, dependencies, and build pipeline. | TBD | YYYY-MM-DD | TBD | Build metadata, tags, provenance, release process, or accepted-risk ref. | Before external distribution; after pipeline changes. | TBD |
| Infrastructure | IaC/cloud configuration scanning is configured or explicitly deferred if infrastructure is managed as code. | TBD | YYYY-MM-DD | TBD | Checkov, tfsec, Terrascan, cloud posture tool, or `N/A` reason. | Before provisioning production; after IaC/cloud changes. | TBD |
| Infrastructure | Production-like environments have baseline access controls, network exposure review, and least-privilege credentials. | TBD | YYYY-MM-DD | TBD | Architecture docs, cloud/IaC review, environment docs, or follow-up STEP. | Before production use; after hosting changes. | TBD |
| SBOM | SBOM generation is configured, planned, or explicitly deferred based on project maturity and distribution needs. | TBD | YYYY-MM-DD | TBD | Syft, CycloneDX, SPDX output, release pipeline, or deferral reason. | Before enterprise/customer distribution; before regulated use; after S2 requests it. | TBD |
| Monitoring | Security-relevant operational signals are identified: auth failures, admin actions, deploys, secret/config changes, dependency alerts, uptime/health. | TBD | YYYY-MM-DD | TBD | Observability architecture doc, alert rules, logs, or project-specific operations doc. | Before production use; after adding auth/admin surfaces. | TBD |
| Incident readiness | Incident response entry point and escalation owner are documented for security events. | TBD | YYYY-MM-DD | TBD | `runbooks/incident-postmortem.md`; support/on-call doc; owner list. | Before production use; before external users. | TBD |
| Backup/recovery | Backup, restore, and rollback assumptions are recorded for systems holding important data. | TBD | YYYY-MM-DD | TBD | Environment docs, backup policy, restore test, release runbook, or `N/A` reason. | Before storing important production data; after data-store changes. | TBD |
| Data handling | Sensitive data classes and minimum controls are reflected in the Security & Threat Model and Environments docs. | TBD | YYYY-MM-DD | TBD | Architecture docs, ADRs, privacy/compliance docs, or `N/A` reason. | Before collecting sensitive data; after product scope changes. | TBD |

## S0 Completion Criteria

An S0 baseline is complete when:

- Every applicable row in the S0 report has one of the allowed statuses.
- Each `Done` row has evidence.
- Each `Planned`, `Deferred`, and `Accepted Risk` row has an owner and revisit trigger.
- Each meaningful accepted risk or long-lived deferral is recorded in `registries/risks.yml` or
  clearly covered by an existing risk-register row, and each affected checklist row cites the
  specific `RISK-0000` ID in `Risk ref`.
- Follow-up STEPs or issues exist for planned work that must happen before release, production,
  public launch, or sensitive-data handling.
- `registries/security-reviews.yml` points to the completed S0 report.
