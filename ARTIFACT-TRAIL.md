# Throughstone Artifact Trail

Throughstone's main output is not a pile of prompts. It is a durable project memory: a set
of Markdown files that records what the project is, why decisions were made, what work is
planned next, and how later code should keep those decisions true.

This page is a guided tour of that trail. The exact content is project-specific, but the
shape is stable.

## The Short Version

| Artifact | Where it lives | What it gives you |
|----------|----------------|-------------------|
| Project brief | `Code/<project>-docs/overview.md` | The seed: users, scope, constraints, risks, and experience level. |
| STEP roadmap | `prompts/STEP-index.md` | The project plan: every STEP, status, owner, touched repos, and one-line scope. |
| Architecture docs | `Code/<project>-docs/architecture/NN-*.md` | Current design: the system as it is supposed to work now. |
| ADRs | `Code/<project>-docs/adr/ADR-NNNN-*.md` | Decision history: why important choices were made. |
| STEP plans | `Upcoming Prompts/` while active, then `prompts/<phase>/step-NNNN/` | The work contract for a STEP: scope, substeps, ground rules, and done criteria. |
| Substep prompts | `Upcoming Prompts/` while active, then archived with the STEP | Cold-start instructions for one focused task. |
| Check-in reports | Archived with check-in STEPs under `prompts/` | Periodic reconciliation: docs vs. code, conditional coverage, risks, and tests. |

The split matters:

- `Code/<project>-docs/` is **state**: what the system is now.
- `prompts/` is **history**: how the system got there, STEP by STEP.
- `Upcoming Prompts/` is **working scratch** for the active STEP.

## 1. Project Brief

`overview.md` is the project seed. The kickoff interview creates it from your idea, then
later sessions read it so the project does not depend on chat memory.

Representative excerpt:

```md
# acme — Project Overview

<!-- PROJECT-STATUS: kickoff-complete -->

## Your experience level
- [x] 2 — Basic coding experience

## In one sentence
A scheduling assistant that negotiates meeting times for small consulting teams.

## What it does (core capabilities)
- Connect calendar accounts.
- Propose meeting windows across participants.
- Send confirmation links and reminders.

## Sensitive data & risk
Calendar metadata, attendee emails, and meeting notes require careful access control.
```

The template source is
[`Code/{{PROJECT}}-docs/templates/overview-template.md`](Code/{{PROJECT}}-docs/templates/overview-template.md).

## 2. STEP Roadmap

`prompts/STEP-index.md` is the first place to look when resuming. It tells a person or an
agent what exists, what is active, and what comes next.

Representative excerpt:

```md
| STEP | Title | Owner | Status | Repos (projection) | Scope |
|------|-------|-------|--------|--------------------|-------|
| STEP-1 | Architecture | Sam | Done | `acme-docs`, `prompts` | Architecture docs + ADRs, no app code. |
| STEP-2 | Scaffold API service | Sam | Done | `acme-api` | Create service skeleton, CI, health endpoint. |
| STEP-3 | Calendar OAuth | Priya | In progress | `acme-api`, `acme-web` | Connect Google Calendar account flow. |
| STEP-4 | Check-in |  | Planned | all | Reconcile docs/code drift and run full tests. |
```

The seed file is
[`Code/{{PROJECT}}-docs/templates/step-index-seed.md`](Code/{{PROJECT}}-docs/templates/step-index-seed.md).

## 3. Architecture Docs

Architecture docs are living documents. They say what the system is now, carry a version,
and keep decision summaries close to the design.

Representative excerpt:

```md
# Doc 03 — Architecture Overview & Component Boundaries

**Version:** v0.2.0
**Status:** Draft
**Last updated:** 2026-06-23 (STEP-3)
**Audience:** Builders, reviewers, future agents

## Decision Summary

| # | Decision | Choice | Rationale | Forecloses / tradeoff |
|---|----------|--------|-----------|-----------------------|
| 1 | Service split | API + web client | Keeps calendar sync server-side. | More deployment pieces than a static app. |

## Version Log

| Version | Date | STEP | Change |
|---------|------|------|--------|
| v0.2.0 | 2026-06-23 | STEP-3 | Added OAuth callback boundary. |
```

The shared skeleton is
[`Code/{{PROJECT}}-docs/templates/architecture-doc-template.md`](Code/{{PROJECT}}-docs/templates/architecture-doc-template.md).

## 4. ADRs

ADRs are point-in-time records. They preserve the why behind important choices without
turning the architecture docs into a debate transcript.

Representative excerpt:

```md
# ADR-0003: Use Postgres for scheduling state

**Status:** Accepted
**Date:** 2026-06-23

## Context
The product needs transactional updates for invitations, holds, and confirmations.

## Decision
Use Postgres as the primary datastore for Phase 1.

## Consequences
Relational constraints make double-booking easier to prevent, but local development needs a
database service instead of a single embedded file.
```

The template is
[`Code/{{PROJECT}}-docs/templates/adr-template.md`](Code/{{PROJECT}}-docs/templates/adr-template.md).

## 5. STEP Plans and Substep Prompts

A STEP plan defines the unit of work. Substep prompts are written so a fresh agent can run
one task cold, without relying on the conversation that created the plan.

Representative STEP-plan excerpt:

```md
# acme — STEP-3 PLAN: Calendar OAuth

## Decisions already locked
- ADR-0002 — Use hosted OAuth provider.
- architecture/06-security-threat-model.md — tokens are encrypted at rest.

## Substeps

| # | Title | Produces | Depends on | Open questions |
|---|-------|----------|------------|----------------|
| 3.1 | OAuth callback endpoint | API route + tests | ADR-0002 | None |
| 3.2 | Connect-calendar UI | Settings flow + tests | 3.1 | Button copy |
```

Representative substep excerpt:

```md
## Read these first
- overview.md
- architecture/06-security-threat-model.md
- ADR-0002-hosted-oauth-provider.md
- acme-api/README.md

## Verification
- Write tests for success, denied consent, expired state, and provider error.
- Run the API test suite before marking this substep done.

## Keeping the docs true
If token storage changes, update the security architecture doc or write a new ADR.
```

The templates are
[`Code/{{PROJECT}}-docs/templates/step-plan-template.md`](Code/{{PROJECT}}-docs/templates/step-plan-template.md)
and
[`Code/{{PROJECT}}-docs/templates/substep-prompt-template.md`](Code/{{PROJECT}}-docs/templates/substep-prompt-template.md).

## 6. Check-In Reports

Every 10-20 STEPs, a check-in STEP runs a deliberate sweep. It compares architecture docs
against code in both directions, re-evaluates conditional architecture sessions, reviews
accepted risks and debt, and runs the full test suite.

Representative report excerpt:

```md
# STEP-12 Check-In Report

## Drift
- Updated architecture/03-architecture-overview.md for the new worker repo.
- Filed STEP-13 for API pagination drift; the doc was still correct.

## Conditional coverage
- Identity & auth: still included and current.
- Privacy/compliance: trigger fired after calendar metadata retention changed; opened STEP-14.

## Risks/debt
- Closed RISK-002 after token-rotation automation shipped.

## Tests
- API: 218 passed.
- Web: 96 passed.
```

The runbook is
[`Code/{{PROJECT}}-docs/runbooks/check-in.md`](Code/{{PROJECT}}-docs/runbooks/check-in.md).

## Why This Helps

The artifact trail gives future work a place to start:

- A new chat can resume from disk instead of asking you to reconstruct context.
- A reviewer can see whether code matches the architecture or drifted from it.
- A later decision can supersede an ADR instead of silently rewriting history.
- A check-in can catch stale docs, missing conditionals, accepted risks, and broken tests.

This does not make AI coding error-proof. It makes the work inspectable and keeps wrong turns
smaller.
