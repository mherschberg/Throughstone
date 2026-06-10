# {{PROJECT}} — Implementation Planning Session

> **How to run:** Once the architecture STEP (STEP-1) is complete and its
> Cross-Cutting Review is clean, tell your agent *"run the planning session"*. Like the
> architecture sessions it's an interview — it turns the locked architecture into the
> **implementation STEPs** that build Phase 1. It only **outlines** them — a short scope
> each. Authoring the first STEP's PLAN and starting to code is the *next* action, in a fresh
> chat (see "Next" below).
>
> Reads **all** of `architecture/*` (especially the Phasing & Roadmap architecture doc
> `architecture/*-phasing-roadmap.md`, the Architecture Overview architecture doc
> `architecture/*-architecture-overview.md`, and the Interface Contracts architecture doc
> `architecture/*-interface-contracts.md`), `adr/*`,
> `prompts/STEP-index.md`, and — for multi-repo
> projects — `registries/repos.yml`.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## Why this session matters
STEP-1 leaves you with a coherent architecture but no path into code. The instinct is to
"just start building" — which is how the carefully-phased design gets ignored and the work
sprawls. This session does the bridge deliberately: it reads what the architecture
committed to for **Phase 1** and lays it out as an ordered list of buildable STEPs — a short
outline each, not a detailed plan. It's the gate between "we know what to build" and "we're
building it."

It is **re-runnable** (in the spirit of `METHOD.md` §4 — here it revises the STEP outline,
not an architecture doc). Run it once now to lay out the Phase-1 STEPs; re-run it when the
architecture changes and the remaining STEPs need re-planning.

## How this session works
- One decision at a time; show options where useful; **wait** for the answer.
- Pull the Phase-1 scope from the Phasing & Roadmap architecture doc
  (`architecture/*-phasing-roadmap.md`) and the component
  boundaries from the Architecture Overview architecture doc
  (`architecture/*-architecture-overview.md`), plus the contract policy from
  `architecture/*-interface-contracts.md`. Don't re-litigate architecture here — if a
  decision feels wrong, that's a signal to **re-run the relevant session**, not to decide it
  in passing.
- Keep STEPs **small and runnable** — each should be completable and reviewable on its own.
  Push back on a STEP that's really three STEPs.
- **This session only outlines — it writes no code and no detailed plans.** The output is
  the *list* of Phase-1 implementation STEPs, each in a couple of sentences. Each STEP's
  detailed PLAN, substeps, and definition of done are written **later**, when you're about
  to run that STEP (`prompts/README.md` → "Recipe: adding a new STEP"; `METHOD.md` §5).

## What to work through (with the user)
1. **Repo scaffolding.** What repos does the Architecture Overview architecture doc
   (`architecture/*-architecture-overview.md`) / `registries/repos.yml` name? The first implementation STEP is
   almost always *"scaffold the repos and the skeleton"* — create each code repo from
   `templates/repo-readme.md`, wire up the chosen stack, CI, and the environment/secrets
   baseline from the Environments architecture doc, plus any interface contract artifact placeholders or repo-local contract files
   named in the Interface Contracts architecture doc — including copying `templates/env-example.txt` into each repo as its
   `.env.example`, and adding a **stack-appropriate `.gitignore`** to each new code repo
   (language/build artifacts — `node_modules/`, `__pycache__/`, `target/`, `dist/`, … — plus
   the `.env` / `.secrets/` secret-file block so local secrets never get committed). Apply the
   project-license posture too: run
   `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh <new-repo-path>` for every new code
   repo. It reads `.throughstone/project-license`, requires the canonical docs-hub `LICENSE`
   for an open-source selection, and copies that file unchanged. For `Proprietary`, no project
   `LICENSE` is created. It also copies `LICENSE-THROUGHSTONE`, because the standard repo README
   and CI starter are retained Throughstone-authored scaffold material, and writes
   `LICENSING.md` to make clear that notice is not the application-code license. Repository
   visibility is separate: when adding a remote for each code repo, choose private or public
   deliberately rather than inferring it from the license. Publishing a proprietary repo makes
   its source visible without granting open-source reuse rights, so call that out explicitly.
   **Each
   repo's README isn't just stamped — its role one-liner and Overview get filled in** (what
   the repo is and the slice of the system it owns), and the repo gets a row in
   `registries/repos.yml` with a one-line `description`; a repo isn't scaffolded until it can
   explain itself. Confirm the repo list and that they don't exist yet.
2. **The implementation STEP sequence.** Propose all the Phase-1 STEPs in dependency order.
   A typical shape:
   - **Scaffold** — repos, skeleton, CI, local run + the env/secrets baseline.
   - **Core data layer** — the data model from `architecture/*-data-model.md` made real (schema,
     migrations, access layer).
   - **One STEP per core capability** — each Phase-1 capability from the phase plan, built
     against the data layer and component boundaries.
   - **Integration / end-to-end** — wire the capabilities together; the launch-criteria
     path from the phase plan works end to end.
   Adjust to the actual project. Each STEP gets a global STEP number (continuing from
   STEP-1).
3. **Interleave check-in STEPs.** Roughly **every 10–20 STEPs**, add a **Check-in STEP**
   that runs `runbooks/check-in.md` (doc-drift reconciliation + full test run). Place each at
   a sensible breakpoint — after a capability lands, not mid-feature — rather than mechanically
   on a fixed count. For a Phase 1 with only a handful of STEPs, one check-in near the end (or
   none) is fine; use judgment.
4. **Outline each STEP — briefly.** For each STEP (including the check-ins), a short outline:
   what it delivers and how it depends on the others. Roughly **2–3 sentences each** — a
   guideline, not a rule. Don't write the detailed plan, the substeps, or the definition of
   done here; those come when the STEP is started.

## Output
- **Update `prompts/STEP-index.md`:** add a row for every Phase-1 implementation STEP —
  global STEP number, title, status `Planned`, and the short (2–3 sentence) outline as its
  scope — in dependency order after STEP-1. **That list is the whole deliverable.**
  - *In a team:* this batch is a number reservation like any other
    (`runbooks/collaboration.md` §2) — commit it to `prompts/`'s shared trunk and push. If the
    push is rejected, move the **whole block** above the new `max` (not just one row), re-scan
    for duplicate numbers, and push again.
- **Then stop.** Don't create any PLAN or substep-prompt files. When the user is ready to
  build, they start the first STEP — and *that* is when its PLAN and substep prompts get
  authored, per `prompts/README.md`. Re-run this session if the outline needs revising as the
  project learns.

## Next
The outline **is** the deliverable — author no PLANs here. Once the rows are in
`prompts/STEP-index.md`, tell the user the next action: **start a fresh chat** and start the
lowest-numbered `Planned` implementation STEP, authoring its PLAN + substep prompts via
`prompts/README.md` ("Recipe: adding a new STEP"). See the next-action resolver
(`METHOD.md` §10).

Start by reading the Phasing & Roadmap architecture doc (`architecture/*-phasing-roadmap.md`), the Architecture Overview architecture doc
(`architecture/*-architecture-overview.md`),
and the Interface Contracts architecture doc (`architecture/*-interface-contracts.md`), then
work through the points above with the user.
