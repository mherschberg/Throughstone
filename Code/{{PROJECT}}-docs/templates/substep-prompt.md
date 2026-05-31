# {{PROJECT}} — STEP-{{N.M}}: {{SUBSTEP TITLE}}

> **How to run:** Tell your agent *"run substep {{N.M}}"* (or *"read and run this file"*).
> A substep is self-contained — it must be executable cold in a fresh chat. Write it so
> nothing depends on the conversation that produced it.
>
> *(For the architecture STEP-1, use the interview-style session format instead — see
> `templates/architecture-sessions/01-system-overview.md`. This template is for normal
> implementation substeps.)*

## Context
<!-- Where this sits: the STEP it belongs to (link the PLAN), what came before, what this
     substep is responsible for. Enough that a fresh agent understands without history. -->

## Read these first
<!-- Explicit list of files this substep depends on: architecture docs, ADRs, prior code,
     coding standards. The agent should read these before doing anything. -->
- architecture/NN-…
- ADR-XXXX-…
- coding-standards/…

## Scope
<!-- What this substep owns, and — just as important — what it does NOT touch. -->

## Your task
<!-- The concrete work, broken into clear deliverables with expected outputs. -->

## Verification
<!-- How to prove it's done and correct: tests to write/run, commands, checks. -->

## Keeping the docs true  (always)
<!-- The architecture docs are the source of truth for the design. Implementation drifts
     from them unless you actively reconcile. -->
If your work **changes an architecture decision** (the data model, a boundary, a chosen
technology, a scaling/security assumption, anything an `architecture/*` doc states), don't
just change the code:
- **Small/clarifying change:** update the affected `architecture/NN-*.md` and **bump its
  Version Log** (see `METHOD.md` §6).
- **Significant or contested change:** write an **ADR** (`templates/adr.md`) and update the
  doc to match. If it overturns a settled assumption, consider **re-running** the relevant
  architecture session (`METHOD.md` §4).
- **Secrets** stay out of the repo — local values live in the gitignored `.env` /
  `.secrets/` (see `architecture/06-*` and `09-*`); commit only `.env.example`.

Leaving the doc stale is a defect, not a follow-up.

## Definition of done
- [ ]
- [ ]
- [ ] Any architecture decision this substep changed is reflected in the docs (Version Log
      bumped) or recorded in an ADR.

## Next
When this substep is done, update its status in the STEP PLAN, then tell the user the next
action: the next open substep — *"run substep N.M"*, in a **fresh chat** — or, if this was
the last substep, the STEP's review. (`METHOD.md` §10.)
