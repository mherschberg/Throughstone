# {{PROJECT}} — STEP-{{N}} PLAN: {{STEP TITLE}}

**Phase:** {{e.g. Phase 1 — MVP}}
**Owner:** {{who is running this STEP}}        <!-- one owner for the whole STEP and all its substeps; also shown in STEP-index.md; solo: optional -->
**Status:** Planned        <!-- Planned → In progress → Done; or Abandoned (see METHOD.md §1) -->
**Date:** {{DATE}}
**Branch:** `step-{{NNNN}}-{{short-name}}`   <!-- same name in every repo this STEP touches -->
**Repos (projection):** {{repos + merge order}}   <!-- same label as STEP-index.md; lists repos + merge order; powers the overlap warning -->

> One-paragraph statement of what this STEP delivers and why it comes now.

## Motivation
<!-- Why this STEP exists. What it unblocks. Where it sits in the arc of the project. -->

## Decisions already locked
<!-- Decisions from prior STEPs/ADRs that this STEP must respect. Reference by ADR number
     or architecture doc. Carrying these forward keeps a shared mental model. -->
- ADR-XXXX — …
- architecture/NN-… — …

## Substeps

| # | Title | Produces | Depends on | Open questions |
|---|-------|----------|------------|----------------|
| {{N}}.1 |  |  |  |  |
| {{N}}.2 |  |  |  |  |

<!-- For the architecture STEP, substeps are the sessions in
     templates/architecture-sessions/ (1.1 → session 01, etc.). For later STEPs, each
     substep gets a prompt authored from templates/substep-prompt.md. A Check-in STEP is
     thin: no prompts are authored — its two substeps are the doc-drift reconciliation
     (N.1) and full test run (N.2) defined in runbooks/check-in.md; this PLAN just points
     there. -->

## Open questions
<!-- Things still undecided at the start of this STEP. Mark Q1, Q2, … with owner. -->

## Ground rules
<!-- The working agreement for this STEP. e.g. "no code in this STEP", commit discipline,
     what 'done' means for a substep, review gates. -->

## Definition of done
<!-- Concrete, checkable criteria for the whole STEP. -->
- [ ]
- [ ]
- [ ] STEP review passed; STEP-index.md updated; STEP archived to prompts/.
<!-- The "STEP review" is your team's standard PR / code review (a standard-practice gate the
     method doesn't redefine — see runbooks/collaboration.md), plus the doc-drift check from
     templates/substep-prompt.md ("Keeping the docs true"). Exceptions: STEP-1's review is the
     cross-cutting review (session 1.13); a Check-in STEP is itself the review (runbooks/check-in.md). -->
