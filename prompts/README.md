# Prompts

This is where the project's roadmap and archived STEP plans/prompts live — the record of
*how* the project was built, STEP by STEP. See `Code/{{PROJECT}}-docs/METHOD.md` for the
full method; this README covers the conventions here and the recipe for adding a STEP.

**Licensing:** project-authored roadmap and prompt content follows the posture recorded in the
docs hub's `.throughstone/project-license`. Open-source projects carry that selected project
license in the root `LICENSE`; proprietary projects intentionally do not. A missing
open-source `LICENSE` is an error, not a change of posture. Retained Throughstone-authored seed
content and conventions remain under BSD-3-Clause; see `LICENSE-THROUGHSTONE`. The two scopes
describe different material and neither replaces the other.

**`prompts/` is its own repo** — project-wide, spanning all the code repos. It is
**history** (never rewritten); the docs hub (`Code/{{PROJECT}}-docs/`) is **state** (kept
current). `Upcoming Prompts/` is a workspace folder for the in-flight STEP, not generally a
repo (see `METHOD.md` §5).

## Layout

```
prompts/
├── README.md          ← this file (conventions + authoring recipe)
├── STEP-index.md      ← the living roadmap: every STEP, status, scope. Start here.
└── 001-mvp/           ← Phase 1. Archived STEPs land here as they complete.
    ├── README.md      ← per-phase summary table
    └── step-NNNN/     ← one folder per completed STEP: its PLAN + all substep prompts
```

The STEP you're *currently* working on lives in `Upcoming Prompts/` (at the workspace root) as
**loose files** — the PLAN, its substep prompts, and any review doc, named per the conventions
below. There's no `step-NNNN/` subfolder while it's in flight; on completion you **gather those
files into a new `step-NNNN/` folder** in the right phase here (see the recipe, step 6).

## Conventions

- **STEP numbers are global** and never reset. Phase 3 might open at STEP-87.
- **Phase folders:** `NNN-kebab-name/` (`001-mvp/`, `002-public-beta/`).
- **STEP folders (archived):** `step-NNNN/`, four-digit zero-padded (`step-0001/`, `step-0087/`).
- **Filenames** are preserved from when they were written:
  - PLAN: `{{PROJECT}}-STEP-N-PLAN.md`
  - Substep prompt: `{{PROJECT}}-STEP-N.M-PROMPT.md` (fractional substeps like `5a` are fine)
- Each phase folder keeps a `README.md` summary table (from
  `Code/{{PROJECT}}-docs/templates/phase-readme-template.md`), updated by hand as STEPs complete.
  Phase 1 (`001-mvp/`) ships seeded; create `002-<name>/README.md` from the template when
  you open a new phase.

## From architecture to implementation

The implementation STEPs aren't invented one-by-one from a blank index. After STEP-1's
Cross-Cutting Review passes, run the **implementation planning session**
(`Code/{{PROJECT}}-docs/templates/planning-session.md`, *"run the planning session"*): it
reads the locked architecture and **outlines all the Phase-1 implementation STEPs** into
`STEP-index.md` — a short (2–3 sentence) scope each, in dependency order. It stops there: no
PLANs, no substep prompts. From then on you build the STEPs one at a time, authoring each
STEP's PLAN + substep prompts with the recipe below **when you start that STEP**.

The outline also interleaves a **Check-in STEP** every ~10–20 STEPs — a full STEP that runs
`Code/{{PROJECT}}-docs/runbooks/check-in.md` (reconcile docs vs. code both ways, re-check
conditional-session coverage, review accepted risks/debt in
`Code/{{PROJECT}}-docs/registries/risks.yml`, and run the full test suite). Its completed
report is written under `Code/{{PROJECT}}-docs/reports/`; the archived STEP folder here keeps
the thin PLAN. The agent suggests one at a sensible breakpoint if it's been about that long
since the last (see `METHOD.md` §5).

## When not to add a STEP

Not every ticket, bug fix, or small feature needs this recipe. If the work is small,
well-understood, low-risk, and does not change architecture, public contracts, data model,
security posture, deployment behavior, multiple repos, or accepted risk/debt, use the team's
normal issue, branch, PR, test, and commit flow. Reference any external ticket in the branch,
PR, or commit message instead of reserving a STEP number.

Add or promote to a STEP when the work needs planning context, sequencing, coordination,
cross-repo handling, architecture/doc review, or a durable record that a fresh agent or
teammate will need later.

## Recipe: adding a new STEP

> **Write the PLAN and all its substep prompts in a single chat.** One session that holds
> the whole STEP in mind produces coherent substeps. Then, **while executing** the
> substeps, expect to revise later ones: decisions made in an earlier substep often change
> what a later substep should do. Update those prompts (and the PLAN) as you go — they
> should reflect current intent, not the original guess.
>
> STEP planning is an interactive discussion. Confirm the scope before drafting, ask for
> clarification whenever the work is ambiguous, and when a decision is needed offer
> appropriate options with brief pros and cons rather than forcing the user to start from a
> blank page.
> Read the saved **Planning communication style** in `Code/{{PROJECT}}-docs/overview.md`
> and use it as the default verbosity; don't re-ask for every STEP unless the value is
> missing or the user asks to change it.

1. **Reserve the number in the index.** Look up the STEP in `prompts/STEP-index.md`. If it's
   not there, add a row — and that row *is* the number reservation. **Pull first**, take the
   next number (`max + 1`), add the row **on `prompts/`'s shared trunk** (not a `step-NNNN`
   branch), then **commit and push immediately** in a dedicated `reserve STEP-N` commit,
   **before** branching or writing. If the push is rejected, someone reserved concurrently —
   pull, renumber, push again. Before every push, even on a clean merge, scan for a duplicate
   (`grep -oE '^\|[[:space:]]*STEP-[0-9]+' prompts/STEP-index.md | grep -oE 'STEP-[0-9]+' | sort | uniq -d`); two appended rows merge
   with no conflict into a silent duplicate. (Solo with no remote, this is just a local edit.)
   See `Code/{{PROJECT}}-docs/runbooks/collaboration.md`.
2. **Confirm scope** with the user before writing anything — a STEP is a real commitment.
   Ask clarifying questions where the planned work, dependencies, repo ownership, or order
   are uncertain. When there are real alternatives, present appropriate options with short
   pros and cons and let the user choose or adjust. Work the STEP on a branch named
   `step-NNNN-short-name` (the same name in every repo it touches).
3. **Write the PLAN** from `Code/{{PROJECT}}-docs/templates/step-plan-template.md`: motivation,
   locked decisions (reference the ADRs/architecture docs it must respect), the substep
   table, ground rules, and a definition of done. Save it in `Upcoming Prompts/`.
4. **Write the substep prompts** from `Code/{{PROJECT}}-docs/templates/substep-prompt-template.md` —
   one per substep, each self-contained (runnable cold in a fresh chat). Author these in
   the same chat as the PLAN.
   *(For the architecture STEP-1, the substeps are the interview sessions in
   `Code/{{PROJECT}}-docs/templates/architecture-sessions/` — you don't author those from
   scratch. For a **Check-in STEP**, you don't author prompts either — its two substeps are
   the doc-drift/conditional-coverage reconciliation and full test run defined in
   `Code/{{PROJECT}}-docs/runbooks/check-in.md`; the PLAN just points there. An **Incident
   STEP** is the same kind of thin STEP — its three substeps (RCA → find similar → fix) are
   defined in `Code/{{PROJECT}}-docs/runbooks/incident-postmortem.md`, opened by that runbook
   when responding to a production incident; its durable postmortem report starts from
   `Code/{{PROJECT}}-docs/templates/reports/incidents/incident-postmortem-report-template.md`
   and is saved under `Code/{{PROJECT}}-docs/reports/incidents/`. A **late conditional-session
   follow-up STEP** is also thin: its one substep points directly to the applicable
   `templates/architecture-sessions/conditional-*.md` file and records its exact by-name
   invocation plus the assigned output-doc number; don't duplicate the session into a new
   prompt. Give its index row the title `Conditional session: <topic>` so the resolver runs
   it before ordinary planned implementation work.)*
5. **Update `prompts/STEP-index.md`**: set the STEP's status and list its substeps.
6. **On completion:** run the STEP's review — your team's standard **PR / code review** (the
   method doesn't redefine it), plus the doc-drift check — then **gather the STEP's files
   (PLAN + any substep prompts + review) from `Upcoming Prompts/` into a new `step-NNNN/` folder**
   in the phase folder in this repo and mark it **Done** in the index.
   (STEP-1's review is the Cross-Cutting Review; a Check-in STEP is its own review.) Then tell the user
   the next action — the next `Planned` STEP, or a **Check-in STEP** if one is due — via the
   next-action resolver (`Code/{{PROJECT}}-docs/METHOD.md` §10).

> **Multiple contributors** all append to `prompts/` (it's shared history, never rewritten).
> Archived `step-NNNN/` folders are write-once, so they don't conflict; the only shared files
> several hands touch are the phase `README.md` and `STEP-index.md` — edit **only your own
> rows** and never re-sort. See `Code/{{PROJECT}}-docs/runbooks/collaboration.md`.
