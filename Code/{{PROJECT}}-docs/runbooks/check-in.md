# Runbook — Periodic Check-In

> **How to run:** A check-in is its own **STEP** (see `METHOD.md` §5). Roughly **every
> 10–20 STEPs** the roadmap should include a *Check-in STEP* whose job is to run this
> runbook — the agent proposes one at a sensible breakpoint (e.g. after a capability lands,
> not mid-feature). When you run that STEP, tell the agent *"run the check-in"* and it
> follows this file.
>
> **Its PLAN is thin and it has exactly two substeps** — you don't author substep prompts for
> it (like the architecture STEP, it's a special case of the recipe in `prompts/README.md`).
> The two substeps *are* this runbook:
> - **substep N.1 — doc-drift reconciliation** (Part 1 below), and
> - **substep N.2 — full test run** (Part 2 below).
>
> The PLAN just points here and lists those two; record their status in the index/PLAN like
> any other substep.

## Why this runbook exists
Two kinds of rot accumulate quietly while you build: the architecture docs drift away from
the code, and the test suite degrades as STEPs add features faster than they add coverage.
Neither shows up until it hurts. The check-in is a deliberate, periodic sweep that catches
both before they harden — a scheduled "is the project still healthy?" gate, distinct from
the per-substep discipline (each substep already updates the doc it changes; this is the
full reconciliation across everything).

This is a **review + verification** STEP, not feature work. It writes no application code —
it fixes docs, files bugs, and proves the tests pass.

## Part 1 — Doc drift (check **both** directions)  *(substep N.1)*

> **Start with the mechanical pass.** Run `scripts/check.sh` first — in seconds it catches the
> *structural* drift this part otherwise checks by hand: duplicate STEP/ADR numbers, invalid
> statuses, architecture docs missing `Version`/`Status`/Version-Log, and an ADR registry that
> disagrees with the files on disk. Fix anything it flags, then do the judgment-based review
> below (which a script can't: does the doc still describe what the system actually *does*?).

For each `architecture/NN-*.md`, compare the doc against the system as it actually is now —
in both directions, because they catch different problems:

- **Docs vs. code** — the doc claims something the code no longer does (stale doc).
  → **Fix the doc** and bump its Version Log (`METHOD.md` §6); if a real decision was made in
  code but never recorded, **write an ADR** (`templates/adr.md`) and update the doc to match.
- **Code vs. docs** — the code diverges from a decision the doc still gets *right* (the code
  is wrong, not the doc). → **Don't "fix" the doc to bless the drift.** Flag it as a bug /
  follow-up STEP.

Cover the high-drift areas at least: data model (`architecture/*-data-model.md`) vs. the
real schema/migrations; architecture overview (`architecture/*-architecture-overview.md`) and
`registries/repos.yml` vs. the real components/repos;
infrastructure / environments vs. what's deployed; interface contracts vs. the published and
generated artifacts; security vs. the auth and secrets handling actually in place; glossary vs.
the terms the code now uses. Also
reconcile `architecture/README.md`'s index against the docs actually present (a row per doc,
with its current version/status).

Beyond the architecture docs, sweep three things that rot just as quietly:
- **Repo READMEs** — every code repo has one, its **Overview** still describes what the repo
  *is*, and the **Setup / Running / Testing** steps still work from a clean checkout. They're
  stamped once at repo creation and otherwise never re-checked, so they're usually the stalest
  doc a new contributor or agent hits first (and any `ARCHITECTURE.md` still matches the design).
- **Interface contracts** — any contract artifact named by `architecture/*-interface-contracts.md` (OpenAPI /
  GraphQL / protobuf / event schema / JSON Schema / public package interface, etc.) still
  matches what the service, worker, CLI, library, or import/export path actually exposes. A
  drifted contract breaks consumers silently, so treat a mismatch as a real defect (fix the
  contract, or file a bug if the implementation is wrong).
- **Docstrings** — spot-check that docstrings describe what the code *now does*, not what it
  was first written to do. A docstring that lies is worse than none; fix it in place (a doc
  fix, not a bug STEP).

## Part 2 — Run all tests  *(substep N.2)*
- Run the **full** test suite (all repos), not just the area you last touched.
- Record the result: pass/fail counts, anything skipped, and coverage if you track it.
- Any failure is a finding for this check-in — fix it here if small, or file it as a bug
  STEP if not. A red suite must not be left for "later."

## Output
Write a short **check-in report** to the check-in STEP's folder:
- **Drift:** docs reviewed, discrepancies found, classified (doc fixed / ADR written / bug
  filed) — with the fixes applied and the bugs filed.
- **Tests:** the suite result, and what was done about any failures.
- **Carry-forward:** anything that became a new bug/STEP, listed for the index.

Then update `prompts/STEP-index.md` (the check-in STEP is Done; add any bug STEPs it
spawned), apply the doc fixes (Version Logs bumped), and add any new ADRs to
`adr/README.md`. Note when the next check-in is due (~10–20 STEPs out).
