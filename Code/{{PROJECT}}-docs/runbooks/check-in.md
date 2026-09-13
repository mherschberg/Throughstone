# Runbook — Periodic Check-In

> **How to run:** A check-in is its own **STEP** (see `METHOD.md` §5). When you run that STEP,
> tell the agent *"run the check-in"* and it follows this file **end to end** — both substeps, in
> one go. That is a **deliberate exception** to `METHOD.md` §10's rule that an in-progress STEP
> runs only the substep you ask for by name.
>
> **Its PLAN is thin and it has exactly two substeps** — you don't author substep prompts for
> it. The two substeps *are* this runbook:
> - **substep N.1 — doc-drift reconciliation + conditional coverage** (Part 1 below), and
> - **substep N.2 — full test run** (Part 2 below).
>
> Record their status in the index/PLAN like any other substep.

## Why this runbook exists
It's easy to get so in the weeds that things get missed, like doc drift, security issues,
regression testing, etc. The check-in STEP prevents too much debt from accumulating unnoticed.

This is a **review + verification** STEP: it writes no new features — it fixes docs, files bugs,
proves the tests pass, and may make a small corrective code or test fix to clear a failure it
found.

## Part 1 — Doc drift and conditional coverage  *(substep N.1)*

> **Start with the mechanical pass.** From the workspace root, run
> `Code/{{PROJECT}}-docs/scripts/check.sh --check-in` first — it catches the *structural* drift
> this part otherwise checks by hand, and its output names each check. Every `[FAIL]` gets fixed.
> A `[WARN]` gets a decision rather than a reflex fix. Then do the judgment-based review below.

For each **non-`Deprecated`** `architecture/NN-*.md`, compare the doc against the system as it
actually is now — in both directions, because they catch different problems:

- **Docs vs. code** — the doc claims something the code no longer does (stale doc).
  → **Fix the doc** and bump its Version Log (`METHOD.md` §6); if a real decision was made in
  code but never recorded, **write an ADR** (`templates/adr-template.md`) and update the doc to match.
- **Code vs. docs** — the code diverges from a decision the doc still gets *right*.
  → **Don't "fix" the doc to bless the drift.** Flag it as a bug / follow-up STEP.

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

**The repo registry.** `scripts/check.sh --check-in` makes two mechanical checks on
`registries/repos.yml`, and only those two.

- **A row with no `location:`** fails the run. Ask the human where that repo lives and write it
  into the row; don't guess a path. **So does a row the doctor cannot read** — one that does not
  start with its `- name:` line; show the human that row.
- **A row with no `remote:` recorded** is a warning. If the repo already has a remote, record the
  URL. If it has none, give it one — **created private**, widening being a separate decision made
  deliberately later — then push to it and record the URL, because the row records that a remote
  exists and does not prove anything was pushed to it. Or decide here that local-only is still
  fine. **Nothing records that decision**: the warning returns every check-in, which is the point.
  In the mono-repo-for-now layout only the workspace-root row is ever named — the folder rows live
  inside that one repository, so whatever backs the root up backs them up too.

**A repo missing from the registry**, or a row whose Architecture Overview entry disagrees with
it, is fixed by **re-running the registration** (`register-repo.md`), never by editing either
side by hand.

### Conditional-session coverage

Re-evaluate conditional architecture coverage against the system as it exists now. Enumerate
every `templates/architecture-sessions/conditional-*.md` file — do not use a hard-coded topic
list. For each template:

- Read its applicability rule and invocation. Compare the rule with the current architecture,
  implemented code, deployed surfaces, data handled, and product behavior.
- Find its latest recorded disposition. Start with the archived STEP-1 PLAN under
  `prompts/*/step-0001/` (or the in-flight PLAN in `Upcoming Prompts/` if STEP-1 is not yet
  archived), then consider later check-in reports under `reports/` and conditional follow-up STEPs. Do not
  edit archived plans or reports; this check-in report records the new current disposition.
- Confirm that an applicable conditional has a completed output architecture doc, or that
  the latest `Deferred` / `N/A` reason remains valid.
- If the conditional now applies but was never run, its old reason is no longer valid, or
  its existing doc needs a material re-interview rather than an ordinary drift correction,
  first check for an existing `Planned` or `In progress` follow-up for the same template.
  Report and retain that STEP if one exists; do not create a duplicate. Otherwise add a
  **separate follow-up STEP** to `prompts/STEP-index.md` for that conditional. Record which
  earlier assumption changed. Title the row `Conditional session: <topic>` so the
  next-action resolver prioritizes it before ordinary planned implementation work. Do not
  run the architecture interview inside the check-in.

For the shape of a conditional follow-up STEP, see `METHOD.md` §4, "Adding a session".

### Deferred-coverage sweep

Some architecture docs deliberately leave part of their area unwritten, marked in their
`Coverage:` field (`METHOD.md` §6).

Enumerate every **non-`Deprecated`** `architecture/NN-*.md` whose **`Coverage:` field** says
anything other than `full` — **read the field, don't grep for a phrase**. A doc with no `Coverage:`
line at all is fully covered and not swept. For each deferred doc, weigh the postponed area against
what the system now does and what the near-term roadmap will build, and record one explicit
**disposition** in this check-in report:

- **Backfill now — file a STEP.** The area is needed, or now cheap to finish. File a thin
  architecture-only follow-up STEP that *finishes the existing doc* (below).
- **Still defer.** Nothing built or planned yet leans on the postponed area. Record *why* the
  deferral still holds (and, if useful, what would end it); no STEP.
- **Genuinely risky — seed it now.** Forward work is likely to lean on the un-enumerated part
  before the next check-in. File the backfill as a `Planned` STEP **now** *and* add a
  `registries/risks.yml` row with a revisit trigger.

Before filing a backfill STEP, check for an existing `Planned` or `In progress` follow-up for the
same doc; report and retain it if one exists — do not create a duplicate.

A deferred-coverage backfill is a thin, architecture-only STEP, the same shape as a conditional
follow-up: its PLAN has one substep that points directly at the deferred `architecture/NN-*.md`
doc and names the section to finish, and it **reuses that doc's existing number**. Unlike a
conditional follow-up it does **not** take the `Conditional session:` title prefix. Give the row a
descriptive title (e.g. `Deferred-coverage backfill: <doc topic>`).
The session that runs it enumerates the postponed area, clears or narrows the doc's `Coverage:`
line (to `full` once the area is complete), updates related architecture docs and
`architecture/README.md`, and records significant decisions as ADRs. Do not run the write-up inside
the check-in itself.

Beyond the architecture docs, sweep four things:
- **Repo READMEs** — sweep each repo present on this machine, and let its README decide which
  case applies.
  **Stamped from `templates/repo-readme-template.md`** — review the whole file: the **Overview**
  still describes what the repo *is*, the **Setup / Running / Testing** steps still work from a
  clean checkout, and any `ARCHITECTURE.md` still matches the design.
  **Carrying a `## Role in <project>` section instead** — review only that section, down to the
  next `##`, and leave the rest of the file alone. **Neither marker** — don't edit it; just
  re-ask the one question a README has to answer for us: can someone standing in this repo still
  find their way back to the project? Licensing is never re-asked per repo — one posture, in
  `.throughstone/project-license`, covers the project.
- **Interface contract artifacts** — any artifact named by `architecture/*-interface-contracts.md` (OpenAPI /
  GraphQL / protobuf / event schema / JSON Schema / public package interface, etc.) still
  matches what the service, worker, CLI, library, or import/export path actually exposes. Treat a
  mismatch as a real defect (fix the contract, or file a bug if the implementation is wrong).
- **Docstrings** — spot-check that docstrings describe what the code *now does*, not what it
  was first written to do. A docstring that lies is worse than none; fix it in place (a doc
  fix, not a bug STEP).
- **Accepted risks / tech debt** — review `registries/risks.yml`. For every open or monitoring
  item, decide whether the revisit trigger has fired, the severity/owner still matches reality,
  and the documents its `refs:` entries point to still exist and still explain the risk. Close
  items that are mitigated, update stale rows, create missing source artifacts, and file
  follow-up STEPs for anything whose trigger has fired or whose severity is no longer acceptable.

### Inputs sweep

The `inputs/` folder holds **point-in-time** source documents (a PRD, a prior design doc, a
protocol/API spec, UI designs); `architecture/` holds the living truth (`inputs/README.md`,
`METHOD.md` §4). As the build captures that material into `architecture/`, an input's captured
parts go stale — but nothing revisits `inputs/` between check-ins, so a superseded seed keeps
reading as current intent until it's reconciled here.

Read the ledger, `inputs/inputs-index.md` (`README.md` and `inputs-index.md` are guidance, not
inputs). Reconcile it against the architecture docs, **treating only live inputs as current:
`inputs/archive/` is history and is not swept**:

- **Drift into the index.** For each input file under `inputs/` (excluding `inputs/archive/`),
  confirm it has row(s) in the ledger; add `Live` rows for anything imported but never recorded, and
  flag ledger rows whose input file is gone.
- **Newly superseded.** For each `Live` row, check whether a **`Current`** `architecture/` doc (or
  an ADR) now covers that part. If it does, surface it and let the user disposition it: **mark
  `Superseded`** (update the row, name the covering doc) or **keep `Live`**. If an
  input is itself architecture-grade — a protocol/API spec, a formal contract, a finished design
  doc — and still lives only in `inputs/`, flag it to be **lifted** into `architecture/` (often a
  whole-file copy or a light reformat to match doc conventions), then marked `Superseded` here;
  inputs are never the living home. (Use judgment, though — some inputs are better **referenced**
  from `architecture/` and kept here, e.g. a large external standard you only partially implement.)
- **Retire the fully superseded.** When **every** row for an input is `Superseded`, offer to retire
  it: **move the file to `inputs/archive/`** and leave its rows in the ledger as the record.
  **Surface-and-decide — never auto-move or auto-delete a file.**

### Security-review gate

Read `registries/security-reviews.yml` and `runbooks/security-review.md`, then decide whether a
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
Update `registries/security-reviews.yml` only when a review actually runs.

## Part 2 — Run all tests  *(substep N.2)*
- Run the **full** test suite — across every repo you can reach — and name any you can't, so a
  partial sweep reads as partial rather than as clean.
- Record the result: pass/fail counts, anything skipped, and coverage if you track it. Put
  durable test-result or coverage-report details under `reports/test-results/` and summarize the
  important outcome in the check-in report.
- Any failure is a finding for this check-in — fix it here if small, or file it as a bug
  STEP if not.

## Output
Write a short **check-in report** under `reports/` in the docs hub. Use
`templates/reports/check-in-report-template.md` and name the completed report
`reports/YYYY-MM-DD-step-NNNN-check-in-report.md`. Fill in every section of the template; where a
sweep found nothing, say so rather than leaving the section out.

Then update `prompts/STEP-index.md` (the check-in STEP is Done; add any bug or conditional
follow-up STEPs it spawned), apply the doc fixes (Version Logs bumped), add any new ADRs to
`adr/README.md`, and archive the thin check-in PLAN under `prompts/` like any other completed
STEP.

**Last, schedule the next one.** Ask the user when it should be. They answer in their own terms;
turn that into a STEP number or a date and write it into `overview.md`'s
`<!-- NEXT-CHECK-IN: … -->` line, replacing whatever is there, and write the same STEP number or
date into the report's Summary. A check-in that closes without an answer leaves the **old** line
in place and `./doctor.sh status` goes on reporting a check-in due — the one you just ran. That is
not a reason to invent a date: leave the line alone, say in the report's Summary that the next one
isn't scheduled yet, and tell the user it is still waiting on them.
