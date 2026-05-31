# {{PROJECT}} — STEP Index

The living roadmap. Every STEP, its status, and a one-line scope. **This is the first
place to look to understand where the project is.** Keep it current as STEPs are planned,
worked, and completed.

> Status values: **Planned** · **In progress** · **Done** (archived to `prompts/`) ·
> **Abandoned** (reserved but won't be built — keep the row so the number is never reused).
> Flip a STEP to **In progress** when you start it, so the overlap warning can see it.
> STEP numbers are global and never reset (see `METHOD.md` §1, §8).
> **What to do next** is always derivable from this index — see the next-action resolver in
> `METHOD.md` §10.
>
> **Reserving a number (teams):** adding a STEP row *is* reserving its number, on `prompts/`'s
> shared trunk (not a `step-NNNN` branch). Pull `prompts/`, take `max + 1`, add the row, then
> **commit and push immediately** — before branching or working. If the push is rejected, pull,
> renumber, push again. Before every push, even a clean merge, scan for duplicates
> (`grep -oE '^\|[[:space:]]*STEP-[0-9]+' STEP-index.md | grep -oE 'STEP-[0-9]+' | sort | uniq -d`)
> — two appended rows merge with no
> conflict into a silent duplicate. See `runbooks/collaboration.md`.
> **Owner** = who's on it; **Repos** = the repos it expects to touch (a *projection* that may
> change — it powers the overlap warning, it doesn't reserve anything). Solo, leave them blank.

## Phase 1 — MVP

| STEP | Title | Owner | Status | Repos (projection) | Scope (one line) |
|------|-------|-------|--------|--------------------|------------------|
| STEP-1 | Architecture | | Planned | `{{PROJECT}}-docs` | Architecture-first: design docs + ADRs, no code. Substeps = the sessions in `templates/architecture-sessions/`. |

<!-- STEP-1 is the ONLY row at bootstrap. STEP-2 onward are the implementation STEPs — don't
     add them by hand: after STEP-1's review passes, run the planning session
     (templates/planning-session.md) and it outlines all the Phase-1 implementation STEPs
     here (a couple of sentences each), in dependency order after STEP-1. Each STEP's detailed
     PLAN and substeps are written later, when you start that STEP. Example row shape:
     | STEP-2 | Scaffold repos & skeleton | | Planned | `{{PROJECT}}-api` | … | -->


### STEP-1 substeps (architecture sessions)

> Like every STEP, STEP-1 has **one owner**, run on one machine — substeps aren't split
> across people (see `runbooks/collaboration.md` §3). But architecture is a shared
> foundation, so **decide it as a group**: the best setup is the whole team in a room walking
> the sessions together while one person drives the keyboard and commits the docs.

| Substep | Session | Status | Output doc |
|---------|---------|--------|------------|
| 1.1 | System overview, requirements & non-goals | Planned | `architecture/01-…` |
| 1.2 | Phasing & roadmap | Planned | `architecture/02-…` |
| 1.3 | Architecture overview & component boundaries | Planned | `architecture/03-…` |
| 1.4 | Data model, ownership & retention | Planned | `architecture/04-…` |
| 1.5 | Scaling & performance | Planned | `architecture/05-…` |
| 1.6 | Security & threat model | Planned | `architecture/06-…` |
| 1.7 | UI / design system | Planned | `architecture/07-…` |
| 1.8 | Infrastructure & deployment | Planned | `architecture/08-…` |
| 1.9 | Environments | Planned | `architecture/09-…` |
| 1.10 | Observability | Planned | `architecture/10-…` |
| 1.11 | Test strategy | Planned | `architecture/11-…` |
| 1.12 | Glossary | Planned | `architecture/12-…` |
| 1.13 | Cross-cutting review | Planned | review doc |

<!-- Conditional sessions (add rows if they apply): Native app architecture (mobile/desktop);
     Identity & auth. The 1.3 platform question decides whether the app session is needed. -->

## How to add a STEP
See `prompts/README.md` for the authoring recipe.
