# Runbook — Security Review

> **How to run:** Choose the smallest review level that matches the trigger:
> - **S0 — Security Baseline**: establish or re-check the external tooling and project hygiene
>   security depends on.
> - **S1 — Security Sweep**: a lightweight recurring review for drift, advisories, and
>   security-sensitive changes.
> - **S2 — Security Audit**: a deeper structured review against applicable external frameworks
>   and threat areas.
>
> Tell your agent *"run the security baseline"*, *"run the security sweep"*, or
> *"run the security audit"*. Do not run every level by default. If the right level is unclear,
> run S1 first and let it decide whether S0 or S2 is needed.
>
> When a review is created as a STEP, give it a thin PLAN that points back to this runbook and
> breaks the selected review level into substeps. S1 and S2 are expected to be large enough that
> their applicable areas or modules usually become separate substeps.

## Why this runbook exists
Security is not handled once during the architecture interview and then forgotten. The Security
& Threat Model architecture doc records the intended posture; this runbook checks whether the
project still lives up to it, whether new threats have appeared, and whether the supporting
tooling is actually in place.

This runbook is deliberately split into levels so security gets nudged without turning every
periodic check-in into a full audit. S0 checks that the guardrails exist. S1 checks whether
anything has drifted or become newly risky. S2 asks whether the whole posture still stands up.

## Review levels

### S0 — Security Baseline
Purpose: establish or re-check the external security tooling, repository hygiene, and recurring
security practices that the project relies on.

Run S0:
- Strongly recommended before the first release, but not required. If that release is internal,
  closed, or still dev-like, the team may defer S0 with a reason and revisit trigger.
- Earlier only when the user explicitly wants a baseline; S0 is not a project-setup gate.
- After major repo, CI, hosting, deployment, or ownership changes.
- During S2 if the baseline has not been checked recently.

Output: a baseline checklist. Each row records the decision date and one status:
`Done`, `Planned`, `Deferred`, `Accepted Risk`, or `N/A`. `Accepted Risk` requires a reason,
owner, and revisit trigger, and usually creates or updates a row in `registries/risks.yml`.

### S1 — Security Sweep
Purpose: a lightweight recurring review that catches security drift, new advisories, stale
accepted risks, and security-sensitive changes since the last review.

Run S1:
- On the project's chosen cadence.
- When the periodic check-in says a sweep is due.
- After auth, authorization, data, deployment, dependency, AI, integration, or public-surface
  changes.
- When a relevant vulnerability advisory lands.

Output: a short report with scope, findings, fixes, accepted risks, follow-up STEPs, and the
next recommended review date. If the sweep is preparing for release and finds that the baseline
is missing or stale, run S0 or create a follow-up STEP for it. If the sweep finds broad
uncertainty or a high-risk change, create an S2 audit STEP.

### S2 — Security Audit
Purpose: a deeper structured review against the security frameworks and threat areas that apply
to this project.

Run S2:
- Strongly recommended before public launch.
- Before handling sensitive production data, payments, regulated workflows, or materially more
  user trust.
- Quarterly for high-risk production systems.
- After major architecture, identity, infrastructure, AI, API, or data-model changes.
- After a serious incident, once the incident has stabilized and the incident runbook has opened
  the right follow-up work.

Output: a scoped audit report listing the modules reviewed, findings, severity, required fixes,
accepted risks, and follow-up STEPs. Only run modules that apply to the project; do not treat S2
as one universal checklist.

## Security review gate
The periodic check-in (`check-in.md`) should include a short security gate rather than running a
full review automatically.

At each check-in, decide:
- Has the S1 cadence elapsed?
- Has a trigger fired since the last S1 or S2?
- Is S0 due because the first release is approaching, it is stale, or it was invalidated by
  repo/tooling changes?
- Is S2 due by schedule, launch milestone, production milestone, incident follow-up, or
  security-sensitive architecture change?

If a review is due, create a separate STEP for it. Do not run S1 or S2 inside a normal
check-in. Use a **Security Baseline STEP** for S0, a **Security Review STEP** for S1, and a
**Security Audit STEP** for S2.

## Durable review ledger
Each project needs one durable, machine-readable place to answer "when did we last check this?"
and "how much changed since then?" Use `registries/security-reviews.yml` for that ledger.

The ledger schema and project cadence defaults live in `registries/security-reviews.yml`; do not
duplicate them here. The ledger records the latest run for each level and the change markers
captured at that time:
- Review date.
- Review level (`S0`, `S1`, or `S2`).
- Report path.
- Reviewed Git commit/SHA, if the project uses Git.
- Approximate SLOC or equivalent size snapshot, if useful and cheap to collect.
- Commit and SLOC deltas since the previous run of the same review level, if useful.
- Next due date or cadence rule.
- Notes about skipped change markers, if they were impractical to collect.

The ledger is not a substitute for reports. It is the index that lets agents notice that a
review is stale because time, commits, or code size changed materially.

## S0 decision table
An S0 report includes a baseline table. Each row has a dated decision so the project can see not
only the current status, but when that status was last accepted.

Use this shape:

| Area | Baseline item | Status | Decision date | Owner | Reason / evidence | Revisit trigger | Risk ref |
|------|---------------|--------|---------------|-------|-------------------|-----------------|----------|
| TBD | TBD | Done / Planned / Deferred / Accepted Risk / N/A | YYYY-MM-DD | TBD | TBD | TBD | `RISK-0000` or blank |

Rules:
- `Done` needs evidence: a setting, file, workflow, command, policy, or report reference.
- `Planned` needs an owner and target trigger/date.
- `Deferred` needs a reason and revisit trigger.
- `Accepted Risk` needs a risk-register row unless the risk is already fully captured by an
  existing referenced artifact.
- `N/A` needs a reason so future reviewers can tell whether the project changed.

## Reports and follow-up work
Every S0, S1, or S2 run writes a short report under `reports/security/` in the docs hub. In a
multi-repo project, that is the documentation repo. In a mono-repo project, it is the
scaffolded docs folder inside the repo. The STEP tracks the work; the report artifact does not
live in the STEP folder.

Use the naming convention in `reports/security/README.md`, then record that report path in
`registries/security-reviews.yml`.

Each report records:
- Review level and date.
- Trigger.
- Scope included and scope intentionally skipped.
- Change markers since the last relevant review: elapsed time, reviewed commit, commits since
  previous review, current rough SLOC or equivalent, rough SLOC delta, and major
  architecture/product changes.
- Findings and fixes applied.
- Accepted risks added or updated in `registries/risks.yml`.
- Follow-up STEPs created or already pending.
- Ledger update made.
- Next recommended review date or trigger.

Security findings that are small and low-risk may be fixed during the review. Larger work becomes
a follow-up STEP. A serious active vulnerability, compromise, data exposure, or malicious
dependency is an incident; switch to `incident-postmortem.md` instead of treating it as a normal
review.

## Relationship to other security docs
- The Security & Threat Model architecture doc defines the intended security posture.
- `dependency-supply-chain.md` remains the focused procedure for dependency vetting and
  dependency vulnerability audits; S1 and S2 call it rather than duplicating it.
- `secrets-rotation.md` remains the focused procedure for planned secret rotation and suspected
  secret exposure.
- `registries/risks.yml` is the durable index for accepted security risks and deferrals.
- `registries/security-reviews.yml` is the durable index for review dates, cadence, and change
  markers.

## Detail placeholders
The detailed S0 checklist, S1 sweep checklist, and S2 audit modules are intentionally defined in
separate passes. Future passes should also add structured report templates for S0, S1, and S2
and update this runbook to point at them. Until then, use the purposes, triggers, outputs, and
ledger rules above to keep the process consistent without pretending the detailed security
checklist is complete.
