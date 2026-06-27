# Runbooks

Repeatable procedures for recurring, higher-stakes moments: reviews, audits, operational
actions, incident response, dependency hygiene, releases, security checks, and collaboration.
Some runbooks inspect code; some operate the system; many do both. Each runbook is the durable
"how we do this" for one such moment, including when to run it, so the procedure doesn't get
improvised under pressure.

## Two kinds of runbook
The method (`../METHOD.md`) draws a line that matters for how you *invoke* each one:

- **STEP-shaped** — runs as a tracked STEP with substeps that record status in the
  `prompts/STEP-index.md`/PLAN. Its PLAN is thin and points at the runbook; you don't author substep
  prompts for it (the same special case as the architecture STEP — see `prompts/README.md`).
  The **check-in** is one; the **incident** follow-up (Parts 2–4) becomes one; security
  reviews become one when the check-in gate or project cadence says a separate review is due.
- **Operational procedure** — *not* a STEP. You run it in the moment by telling the agent the
  trigger phrase below, and it follows the file. The **release**, **dependency** vetting/audit,
  **secrets rotation**, **an explicitly requested early S0 security baseline**, and the **incident** Part-1
  response are these. **Collaboration** is neither — it's reference you read once when a second
  contributor joins. Throughstone scaffold/method updates live separately at
  `../UPDATING-THROUGHSTONE.md`.

The shipped runbooks are **defaults you customize** — they deliberately leave CI/CD, release
versioning, and ecosystem-specific commands to your team's tooling. The *discipline* is the
durable part; fill in your project's specifics.

New-contributor onboarding is intentionally not a runbook. It is project setup and
first-contribution STEP guidance, so it lives at [`../ONBOARDING.md`](../ONBOARDING.md).

## Index

| Runbook | Purpose (one line) | When it fires | Governed by |
|---------|--------------------|---------------|-------------|
| [`check-in.md`](check-in.md) | Doc-drift reconciliation (both directions), conditional-session coverage, accepted risk/debt review, and a full test run — the periodic "is the project still healthy?" gate. | A **STEP**, roughly every 10–20 STEPs; *"run the check-in."* | `METHOD.md` §5 (*Check-in STEPs*); `AGENTS.md`; `registries/risks.yml` |
| [`security-review.md`](security-review.md) | Layered security reviews: S0 baseline tooling/hygiene, S1 recurring sweep, and S2 deeper audit, with a durable ledger for last-run dates and change markers. | Usually a separate **STEP**; the check-in only decides whether one is due — *"run the security baseline/sweep/audit."* | Security & Threat Model architecture doc (`architecture/*-security-threat-model.md`); `registries/risks.yml`; `registries/security-reviews.yml` |
| [`release-deploy.md`](release-deploy.md) | Ship a version safely: rollback plan **before** deploy, reversible migrations, a watch window, one clear lever back. | Operational; whenever you ship/roll back — *"run the release."* | Infrastructure & Deployment architecture doc (`architecture/*-infrastructure-deployment.md`), Environments architecture doc (`architecture/*-environments.md`) |
| [`incident-postmortem.md`](incident-postmortem.md) | Stabilize a production failure (Part 1), then a blameless RCA → find-similar → fix as a follow-up STEP (Parts 2–4) with a postmortem from `templates/incident-postmortem.md`. | Operational on an incident — *"run the incident runbook"*; follow-up is a **STEP**. | `release-deploy.md` (rollback); `METHOD.md` §5 (STEP shape) |
| [`dependency-supply-chain.md`](dependency-supply-chain.md) | Vet a dependency **before** adding it (Part 1); audit installed deps on a cadence (Parts 2–3). | Operational; before `install`/`add` — *"vet this dependency"*; audit rides the check-in or a new advisory. | Security & Threat Model architecture doc (`architecture/*-security-threat-model.md`); `registries/risks.yml` for accepted deferrals |
| [`secrets-rotation.md`](secrets-rotation.md) | Rotate secrets with no downtime on a cadence (Part 1); revoke-first emergency response to a suspected leak (Part 2). | Operational; on a cadence — *"rotate the secrets"*; on exposure — *"we may have leaked a secret."* | Security & Threat Model architecture doc (`architecture/*-security-threat-model.md`) |
| [`collaboration.md`](collaboration.md) | How more than one contributor — human or agent — works without colliding: STEP/ADR numbering, branch-per-STEP, shared-file edits. | Reference; read it when a second contributor joins (solo, mostly a no-op). | `METHOD.md` §6, §8; `AGENTS.md` (team conventions) |
