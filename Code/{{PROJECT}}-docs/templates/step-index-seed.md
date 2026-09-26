# {{PROJECT}} — STEP Index

The living roadmap. Every STEP, its status, and a one-line scope. **This is the first
place to look to understand where the project is.** Keep it current as STEPs are planned,
worked, and completed.

> Status values: **Planned** · **In progress** · **Done** (archived to `prompts/`) ·
> **Deferred** (consciously not needed now; keep a revisit trigger) ·
> **Abandoned** (reserved but won't be built — keep the row so the number is never reused).
> Those five are the STEP states. A **substep** row uses the same values plus **N/A** (this area
> structurally doesn't apply — an API-only system's UI session, say); keep the row either way, since
> the next-action resolver skips `Deferred`, `Abandoned` and `N/A` rather than reading an absence
> (`METHOD.md` §10).
> Flip a STEP to **In progress** when you start it — the next-action resolver reads it.
> STEP numbers are global and never reset (see `METHOD.md` §1, §8).
> **What to do next** is always derivable from this index — see the next-action resolver in
> `METHOD.md` §10.
>
> **Reserving a number:** adding a STEP row *is* reserving its number — take `max + 1` and add the
> row on the trunk, never a `step-NNNN` branch, before you branch or write. In a team, follow
> `Code/{{PROJECT}}-docs/runbooks/collaboration.md` §2.
> **Owner** = who's on it; solo, leave it blank.

## Phase 1 — {{PHASE_1_NAME}}
<!-- {{PHASE_1_NAME}}: kickoff (BOOTSTRAP-PROMPT.md Stage 1) fills this with the chosen phase
     name — MVP (the default) / POC / prototype / v1. Its kebab-case form later names the
     001-<phase-name>/ archive folder, created when STEP-1 is archived. init.sh leaves the
     placeholder as-is; Check 8 parses the table rows below, not this heading. -->

| STEP | Title | Owner | Status | Scope (one line) |
|------|-------|-------|--------|------------------|
| STEP-1 | Architecture | | Planned | Architecture-first: design docs + ADRs, no code. Substeps = the sessions in `templates/architecture-sessions/`. `init.sh` reserves this row; kickoff flips it to `In progress` and uses branch `step-0001-architecture` where branch-per-STEP applies. |

<!-- STEP-1 is the ONLY row at bootstrap. STEP-2 onward are the implementation STEPs — don't
     add them by hand: after STEP-1's review passes, run the planning session
     (templates/planning-session.md) and it outlines all the Phase-1 implementation STEPs
     here (a couple of sentences each), in dependency order after STEP-1. Each STEP's detailed
     PLAN and substeps are written later, when you start that STEP. Starting a STEP means
     planning it and stopping for approval before any substep runs. Example row shape:
     | STEP-2 | Scaffold repos & skeleton | | Planned | … | -->


### STEP-1 substeps (architecture sessions)

> Like every STEP, STEP-1 has **one owner**, run on one machine — substeps aren't split
> across people (see `runbooks/collaboration.md` §3). But architecture is a shared
> foundation, so **decide it as a group**: the best setup is the whole team in a room walking
> the sessions together while one person drives the keyboard and commits the docs.

| Substep | Session | Status | Output doc |
|---------|---------|--------|------------|
| 1.1 | System Overview, Requirements & Non-Goals | Planned | `architecture/01-…` |
| 1.2 | Phasing & Roadmap | Planned | `architecture/02-…` |
| 1.3 | Architecture Overview & Component Boundaries | Planned | `architecture/03-…` |
| 1.4 | Data Model, Ownership & Retention | Planned | `architecture/04-…` |
| 1.5 | Scaling & Performance | Planned | `architecture/05-…` |
| 1.6 | Security & Threat Model | Planned | `architecture/06-…` |
| 1.7 | UI / Design System | Planned | `architecture/07-…` |
| 1.8 | Infrastructure & Deployment | Planned | `architecture/08-…` |
| 1.9 | Environments | Planned | `architecture/09-…` |
| 1.10 | Observability | Planned | `architecture/10-…` |
| 1.11 | Interface Contracts | Planned | `architecture/11-…` |
| 1.12 | Test Strategy | Planned | `architecture/12-…` |
| 1.13 | Glossary | Planned | `architecture/13-…` |
| 1.14 | Cross-Cutting Review | Planned | review doc |

<!-- Conditional sessions: enumerate every conditional-*.md template and include/defer/skip it
     in the STEP-1 PLAN's "Conditional sessions considered" table. Add an index row only when
     one is included. Slot included conditionals under a LETTERED substep after the related
     owning session, and run them BY NAME, not number (for example, "run the identity-auth
     session" → conditional-identity-auth.md). The output doc takes the next number above the
     core set. EXAMPLE ONLY — do not parse this as a real row; real rows start at the left
     margin above this comment, with the assigned substep and doc number:
       | 1.Xa | Conditional topic | Planned | `architecture/NN-topic.md` |
     If a conditional row is later added and then consciously not needed under the current
     project shape, mark it Deferred with the revisit trigger in the PLAN/risk register. -->

## How to add a STEP
See `prompts/README.md` for the authoring recipe.
