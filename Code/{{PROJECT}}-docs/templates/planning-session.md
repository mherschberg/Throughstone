# {{PROJECT}} — Implementation Planning Session

> **How to run:** Once the architecture STEP (STEP-1) is complete and its
> Cross-Cutting Review is clean, tell your agent *"run the planning session"*. Like the
> architecture sessions it's an interview — it turns the locked architecture into the
> **implementation STEPs** that build the target phase — **Phase 1 on a new project**. It only **outlines** them — a short scope
> each. Authoring the first STEP's PLAN and starting to code is the *next* action, in a fresh
> chat (see "Next" below).
>
> Reads **all** of `architecture/*` (especially the Phasing & Roadmap architecture doc
> `architecture/*-phasing-roadmap.md`, the Architecture Overview architecture doc
> `architecture/*-architecture-overview.md`, and the Interface Contracts architecture doc
> `architecture/*-interface-contracts.md`), `adr/*`, anything still live in `inputs/` (point-in-time
> specs or prior docs you provided — e.g. a protocol spec the build must satisfy; skip
> `inputs/archive/`, and where an `architecture/` doc already covers an input, that doc wins),
> `prompts/STEP-index.md`, and — for multi-repo
> projects — `registries/repos.yml`.
> **Calibrate to the local user profile.** Check the **Experience level** in root `.throughstone/local-user.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. If the file is missing, ask the two local-profile questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, then continue. Also check **Communication style** there and use it as the default verbosity for this planning session; an explicit style request in chat overrides it for this session only. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (See `METHOD.md` §4, "Calibrating to the user's experience level".)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}
<!-- The kickoff fills this from overview.md. Running standalone? Read overview.md first. -->

## Why this session matters
STEP-1 leaves you with a coherent architecture but no path into code. The instinct is to
"just start building" — which is how the carefully-phased design gets ignored and the work
sprawls. This session does the bridge deliberately: it reads what the architecture
committed to for **the target phase** and lays it out as an ordered list of buildable STEPs — a short
outline each, not a detailed plan. It's the gate between "we know what to build" and "we're
building it."

It is **re-runnable** (in the spirit of `METHOD.md` §4 — here it revises the STEP outline,
not an architecture doc). Run it once now to lay out the target phase's STEPs; re-run it when the
architecture changes and the remaining STEPs need re-planning.

On a re-run, preserve roadmap history: never renumber or delete an existing STEP, and do not
rewrite `Done` work. Reconcile the remaining rows instead — update still-valid `Planned`
scopes, mark a reserved row `Deferred` or `Abandoned` when appropriate, and append genuinely
new work at `max + 1`. If a changed decision affects an `In progress` STEP, revise that
STEP's PLAN with its owner rather than silently replacing its index row.

## How this session works
- One decision at a time; show options where useful; **wait** for the answer.
- When a decision is not obvious, offer plausible options with brief pros and cons.
  Ask clarifying questions instead of guessing, and use the saved communication style in
  root `.throughstone/local-user.md` unless the user gives an explicit style instruction for
  this session.
- **Target the first uncompleted phase** — the lowest-numbered roadmap phase whose STEPs
  aren't all complete (from `prompts/STEP-index.md` and the Phasing & Roadmap doc),
  **defaulting to Phase 1 on the first run**. A re-run after that phase is done targets the
  next; everything below plans that one phase — **the target phase**.
- Pull the target phase's scope from the Phasing & Roadmap architecture doc
  (`architecture/*-phasing-roadmap.md`) and the component
  boundaries from the Architecture Overview architecture doc
  (`architecture/*-architecture-overview.md`), plus the contract policy from
  `architecture/*-interface-contracts.md`. Don't re-litigate architecture here — if a
  decision feels wrong, that's a signal to **re-run the relevant session**, not to decide it
  in passing.
- Keep STEPs **small and runnable** — each should be completable and reviewable on its own.
  Push back on a STEP that's really three STEPs.
- **This session only outlines — it writes no code and no detailed plans.** The output is
  the *list* of the target phase's implementation STEPs, each in a couple of sentences. Each STEP's
  detailed PLAN, substeps, and definition of done are written **later**, when you're about
  to run that STEP (`prompts/README.md` → "Recipe: adding a new STEP"; `METHOD.md` §5).

## What to work through (with the user)
1. **Repo scaffolding.** What repos does the Architecture Overview architecture doc
   (`architecture/*-architecture-overview.md`) / `registries/repos.yml` name? On a first run none
   of them exist yet, so you scaffold them all — the usual case. Just skip any that are
   **already there:** a repo the architecture names is already there when it has a
   `registries/repos.yml` row **with a filled-in README** (a real role one-liner + Overview, not
   the template's placeholders), so don't re-create it. A repo **registered in place** is likewise
   already there: it exists, and its README is its own — a thin one, or none, is not a reason to
   scaffold over it. This only comes up on a **re-run** (a repo
   you scaffolded in an earlier run is already registered) or when the project already has some of
   these repos; if `registries/repos.yml` is absent or has no code-repo rows yet (that first run,
   or a mono-repo), nothing is registered and every named repo scaffolds, exactly as before.
   When repos still need creating — a first run, the usual case — the first implementation
   STEP is almost always *"scaffold the repos and the skeleton"*: create each new code repo from
   `templates/repo-readme-template.md`, wire up the chosen stack, CI, and the environment/secrets
   baseline from the Environments architecture doc, plus any interface contract artifact placeholders or repo-local contract files
   named in the Interface Contracts architecture doc — including copying `templates/env-example.txt` into each new code repo as its
   `.env.example`, and adding a **stack-appropriate `.gitignore`** to each new code repo
   (language/build artifacts — `node_modules/`, `__pycache__/`, `target/`, `dist/`, … — plus
   the `.env` / `.secrets/` secret-file block so local secrets never get committed). Apply the
   license posture too: run
   `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh <new-repo-path>` for every new code
   repo. It reads `.throughstone/project-license` — which covers Throughstone-authored and
   method-created material, not code the method didn't write — requires the canonical docs-hub `LICENSE`
   for an open-source selection, and copies that file unchanged. For `Proprietary`, no project
   `LICENSE` is created. It also copies `LICENSE-THROUGHSTONE`, because the standard repo README
   and CI starter are retained Throughstone-authored scaffold material, and writes
   `LICENSING.md` to make clear that notice is not the application-code license. **Run it only on
   repos you create** — a repo **registered in place**, which existed before this project did,
   keeps the licensing its owner set (`METHOD.md` §7: a repo the method did not create keeps what
   it already has — README, CI, and licensing alike). Record what such a repo uses where its
   inventory entry describes it and move on; the helper refuses it. Repository
   visibility is separate: when adding a remote for a repo **you are creating**, choose private or
   public deliberately rather than inferring it from the license — and **take public only from an
   explicit go-ahead**, never from an open-source license, a public sibling repo, or the project
   describing itself as open source. With no answer given, create it private: that is reversible
   and publishing is not (`METHOD.md` §7). Publishing a proprietary repo also makes its source
   visible without granting open-source reuse rights, so call that out explicitly.
   **Each
   repo's README isn't just stamped — its role one-liner and Overview get filled in** (what
   the repo is and the slice of the system it owns), and the repo gets a row in
   `registries/repos.yml` with a one-line `description`; a repo isn't scaffolded until it can
   explain itself.
   **A repo registered in place is not scaffolded at all.** Everything above describes creating a
   repo, and this one already exists — so it is not created, and the license helper is not run on
   it (above). The one thing it may still be owed is the role-and-place framing its README
   probably lacks, and what to do keys on whether a README is there. **If it has one:** add a
   short `Role in {{PROJECT}}` section and leave every existing section alone — never stamp the
   template over it. **If it has none:** write its README from the template — that one file, and
   not the `ARCHITECTURE.md` its Overview comment suggests for a complex repo; an in-place repo's
   internal design is written up in the docs hub's `architecture/`, not as a new file at its root.
   Either way it is the user's repo, so show them what you intend to add and where, and wait for a
   yes. **On a yes, commit it on a branch and stop** — commit only the file you proposed, never
   `git add -A`, and **never push, open a PR, or merge**. Tell them the branch and commit and let
   them take it through their own process; how a change reaches their trunk is theirs to decide
   (`METHOD.md` §7). **Its CI is
   its own** — never install `templates/ci/code-repo-ci.yml` into it; record what it runs in the
   Test Strategy doc. **Its remote and its visibility are its own too** — it already lives
   somewhere and is already private or public, so create no remote for it, repoint no existing one,
   and **never change its visibility**. Record the cloneable URL it already has in its `remote:`
   field so `scripts/setup-workspace.sh` can find it, and change nothing about the repo. If the
   README addition is accepted, run
   `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh --notice-only <repo-path>` to place the
   Throughstone notice for that retained material; if it was declined, nothing is owed.
   Confirm the repo list with the user — on a first run they're all new; note any
   that already exist (registered and present, by either of the tests above) so you scaffold only
   the new ones.
2. **The implementation STEP sequence.** Propose all the target phase's STEPs in dependency order —
   **build or extend what this milestone needs, given what already exists.** On a first run
   nothing is built yet, so scaffolding and the core data layer come first and you build
   outward from there; that's the usual case, and the typical shape is:
   - **Scaffold** — repos, skeleton, CI, local run + the env/secrets baseline.
   - **Core data layer** — the data model from `architecture/*-data-model.md` made real (schema,
     migrations, access layer).
   - **One STEP per core capability** — each target-phase capability from the phase plan, built
     against the data layer and component boundaries.
   - **Integration / end-to-end** — wire the capabilities together; the launch-criteria
     path from the phase plan works end to end.
   On a **re-run**, or a later phase whose scaffold and core data layer already exist, start
   from what's built and plan the STEPs that **extend** it, rather than re-scaffolding or
   rebuilding what's already there. Adjust to the actual project. Each STEP gets a
   global STEP number (continuing from STEP-1).
3. **Interleave check-in STEPs.** About **every 20 STEPs** (the project's cadence, adjustable), add a **Check-in STEP**
   that runs `runbooks/check-in.md` (doc-drift reconciliation, conditional-session coverage,
   accepted-risk review, and a full test run). Place each at a sensible breakpoint — after a
   capability lands, not mid-feature — rather than mechanically on a fixed count. For a
   target phase with only a handful of STEPs, one check-in near the end (or none) is fine; use
   judgment.
4. **Outline each STEP — briefly.** For each STEP (including the check-ins), a short outline:
   what it delivers and how it depends on the others. Roughly **2–3 sentences each** — a
   guideline, not a rule. Don't write the detailed plan, the substeps, or the definition of
   done here; those come when the STEP is started.

**Testing note.** When a planned STEP clearly creates a new test surface (API, user flow, data
path, integration boundary, migration, authorization rule, or performance-sensitive path),
mention the expected test tier in the STEP outline. Keep this at the outline level; the
detailed test plan belongs in the STEP PLAN when that STEP starts.

## Output
- **Update `prompts/STEP-index.md`:** add a row for every implementation STEP of the target phase —
  global STEP number, title, status `Planned`, and the short (2–3 sentence) outline as its
  scope — in dependency order after STEP-1. **That list is the whole deliverable.** On a
  re-run, follow the history-preserving rules above instead of adding duplicate rows.
  - *In a team:* this batch is a number reservation like any other
    (`runbooks/collaboration.md` §2) — commit it to `prompts/`'s shared trunk and push. If the
    push is rejected, move the **whole block** above the new `max` (not just one row), re-scan
    for duplicate numbers, and push again.
- **Then stop.** Don't create any PLAN or substep-prompt files. When the user is ready to
  build, they start the first STEP — and *that* is when its PLAN and substep prompts get
  authored, per `prompts/README.md`. Starting that STEP still stops after planning; substeps
  run only after explicit approval. Re-run this session if the outline needs revising as the
  project learns.

## Next
The outline **is** the deliverable — author no PLANs here. Once the rows are in
`prompts/STEP-index.md`, tell the user the next action: **start a fresh chat** and start the
lowest-numbered `Planned` implementation STEP, authoring its PLAN + substep prompts via
`prompts/README.md` ("Recipe: adding a new STEP"), then stopping for approval before any
substep runs. See the next-action resolver
(`METHOD.md` §10).

Start by reading the Phasing & Roadmap architecture doc (`architecture/*-phasing-roadmap.md`), the Architecture Overview architecture doc
(`architecture/*-architecture-overview.md`),
and the Interface Contracts architecture doc (`architecture/*-interface-contracts.md`), then
work through the points above with the user.
