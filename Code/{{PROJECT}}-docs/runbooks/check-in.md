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
> - **substep N.1 — doc-drift reconciliation + conditional coverage** (Part 1 below), and
> - **substep N.2 — full test run** (Part 2 below).
>
> The PLAN just points here and lists those two; record their status in the index/PLAN like
> any other substep.

## Why this runbook exists
Three kinds of rot accumulate quietly while you build: the architecture docs drift away from
the code, a once-irrelevant architecture area becomes applicable without its conditional
session ever running, and the test suite degrades as STEPs add features faster than they add
coverage. They rarely show up until they hurt. The check-in is a deliberate, periodic sweep
that catches them before they harden — a scheduled "is the project still healthy?" gate,
distinct from the per-substep discipline (each substep already updates the doc it changes;
this is the full reconciliation across everything).

This is a **review + verification** STEP, not feature work. It writes no application code —
it fixes docs, files bugs, and proves the tests pass.

## Part 1 — Doc drift and conditional coverage  *(substep N.1)*

> **Start with the mechanical pass.** Run `scripts/check.sh` first — in seconds it catches the
> *structural* drift this part otherwise checks by hand: duplicate STEP/ADR numbers, invalid
> statuses, architecture docs missing `Version`/`Status`/Version-Log, and an ADR registry that
> disagrees with the files on disk, plus architecture-session numbering and conditional-template
> contract drift. Fix anything it flags, then do the judgment-based review below (which a
> script can't: does the doc still describe what the system actually *does*?).

For each `architecture/NN-*.md`, compare the doc against the system as it actually is now —
in both directions, because they catch different problems:

- **Docs vs. code** — the doc claims something the code no longer does (stale doc).
  → **Fix the doc** and bump its Version Log (`METHOD.md` §6); if a real decision was made in
  code but never recorded, **write an ADR** (`templates/adr-template.md`) and update the doc to match.
- **Code vs. docs** — the code diverges from a decision the doc still gets *right* (the code
  is wrong, not the doc). → **Don't "fix" the doc to bless the drift.** Flag it as a bug /
  follow-up STEP.

Cover the high-drift areas at least: the Data Model architecture doc
(`architecture/*-data-model.md`) vs. the real schema/migrations; the Architecture Overview
architecture doc (`architecture/*-architecture-overview.md`) and
`registries/repos.yml` vs. the real components/repos;
the Infrastructure & Deployment architecture doc and the Environments architecture doc vs. the
deployed infrastructure and environments; the Interface Contracts architecture doc vs.
the published and generated artifacts; security vs. the auth and secrets handling actually in
place; the Glossary architecture doc vs. the terms the code now uses. Also
reconcile `architecture/README.md`'s index against the docs actually present (a row per doc,
with its current version/status).

### Conditional-session coverage

Re-evaluate conditional architecture coverage against the system as it exists now. Enumerate
every `templates/architecture-sessions/conditional-*.md` file — do not use a hard-coded topic
list, because projects may add conditional sessions later. For each template:

- Read its applicability rule and invocation. Compare the rule with the current architecture,
  implemented code, deployed surfaces, data handled, and product behavior.
- Find its latest recorded disposition. Start with the archived STEP-1 PLAN under
  `prompts/*/step-0001/` (or the in-flight PLAN in `Upcoming Prompts/` if STEP-1 is not yet
  archived), then consider later check-in reports under `reports/` and conditional follow-up STEPs. Do not
  edit archived plans or reports; this check-in report records the new current disposition.
- Confirm that an applicable conditional has a completed output architecture doc, or that
  the latest `Deferred` / `N/A` reason remains valid. A newly added template with no earlier
  record still needs an explicit current disposition in this check-in report.
- If the conditional now applies but was never run, its old reason is no longer valid, or
  its existing doc needs a material re-interview rather than an ordinary drift correction,
  first check for an existing `Planned` or `In progress` follow-up for the same template.
  Report and retain that STEP if one exists; do not create a duplicate. Otherwise add a
  **separate follow-up STEP** to `prompts/STEP-index.md` for that conditional. Record which
  earlier assumption changed. Title the row `Conditional session: <topic>` so the
  next-action resolver prioritizes it before ordinary planned implementation work. Do not
  run the architecture interview inside the check-in.

A conditional follow-up is a thin, architecture-only STEP: its PLAN has one substep that
points directly to the `conditional-*.md` template and records the template's exact
by-name invocation and assigned output-doc number; reuse the existing doc number for a
re-interview, otherwise take the next free number above the core block. Do not author a
duplicate substep prompt. The session writes or revises its architecture doc, updates
related architecture docs and `architecture/README.md`, and records significant decisions
as ADRs. Its review checks the new decisions against the rest of the architecture. Before
returning to implementation, re-run the planning session if those decisions change the
remaining roadmap.

Beyond the architecture docs, sweep four things that rot just as quietly:
- **Repo READMEs** — every code repo has one, its **Overview** still describes what the repo
  *is*, and the **Setup / Running / Testing** steps still work from a clean checkout. They're
  stamped once at repo creation and otherwise never re-checked, so they're usually the stalest
  doc a new contributor or agent hits first (and any `ARCHITECTURE.md` still matches the design).
- **Interface contract artifacts** — any artifact named by `architecture/*-interface-contracts.md` (OpenAPI /
  GraphQL / protobuf / event schema / JSON Schema / public package interface, etc.) still
  matches what the service, worker, CLI, library, or import/export path actually exposes. A
  drifted contract breaks consumers silently, so treat a mismatch as a real defect (fix the
  contract, or file a bug if the implementation is wrong).
- **Docstrings** — spot-check that docstrings describe what the code *now does*, not what it
  was first written to do. A docstring that lies is worse than none; fix it in place (a doc
  fix, not a bug STEP).
- **Accepted risks / tech debt** — review `registries/risks.yml`. For every open or monitoring
  item, decide whether the revisit trigger has fired, the severity/owner still matches reality,
  and the referenced architecture section, ADR, issue, archived STEP plan/execution notes,
  incident postmortem report under `reports/incidents/`, or check-in report under `reports/`
  still exists and still explains the risk. Close items that are mitigated, update stale rows,
  create missing source artifacts, and file follow-up STEPs for anything whose trigger has
  fired or whose severity is no longer acceptable.

### Security-review gate

Nudge security deliberately, but do not turn every check-in into a full audit. Read
`registries/security-reviews.yml` and `runbooks/security-review.md`, then decide whether a
security review is due:

- Has the S1 Security Sweep cadence elapsed?
- Has a trigger fired since the last S1 or S2 — auth/AuthZ change, sensitive-data change,
  public API/surface change, payment or regulated workflow, AI/agent/tool-calling capability,
  infrastructure/deployment change, major dependency advisory, or incident follow-up?
- Is the S0 Security Baseline due because the first release is approaching, it is stale, or it
  was invalidated by repo, CI, hosting, deployment, or ownership changes?
- Is an S2 Security Audit due by schedule, launch/production milestone, incident follow-up, or
  material security-posture change?

If a review is due, add a separate STEP for it; do not run S1 or S2 inside this check-in. Use a
**Security Baseline STEP** for S0, a **Security Review STEP** for S1, and a **Security Audit
STEP** for S2.
Update `registries/security-reviews.yml` only when a review actually runs, not merely because
the gate was evaluated.

## Part 2 — Run all tests  *(substep N.2)*
- Run the **full** test suite (all repos), not just the area you last touched.
- Record the result: pass/fail counts, anything skipped, and coverage if you track it.
- Any failure is a finding for this check-in — fix it here if small, or file it as a bug
  STEP if not. A red suite must not be left for "later."

## Output
Write a short **check-in report** under `reports/` in the docs hub. Use
`templates/reports/check-in-report-template.md` and name the completed report
`reports/YYYY-MM-DD-step-NNNN-check-in-report.md`.
- **Drift:** docs reviewed, discrepancies found, classified (doc fixed / ADR written / bug
  filed) — with the fixes applied and the bugs filed.
- **Conditional coverage:** every discovered conditional-session template and its current
  disposition; list any whose trigger fired and the follow-up STEP created or already pending.
- **Risks/debt:** `registries/risks.yml` items reviewed, closed, updated, or promoted to
  follow-up STEPs.
- **Security review gate:** S0/S1/S2 current status, whether a review is due, and any Security
  Baseline, Security Review, or Security Audit STEP created.
- **Tests:** the suite result, and what was done about any failures.
- **Carry-forward:** anything that became a new bug/STEP, listed for the index.

Then update `prompts/STEP-index.md` (the check-in STEP is Done; add any bug or conditional
follow-up STEPs it spawned), apply the doc fixes (Version Logs bumped), add any new ADRs to
`adr/README.md`, and archive the thin check-in PLAN under `prompts/` like any other completed
STEP. Note when the next check-in is due (~10–20 STEPs out).
