# {{PROJECT}} — Agent Context

> **Canonical** context for any AI agent working in this project. The per-machine
> `CLAUDE.md` and `AGENTS.md` at the workspace root point here. Tool-agnostic: Claude Code,
> Codex, and others read this convention. **New session? Start with "First action — kickoff
> or resume?" just below.**
>
> **Paths in this file are relative to the workspace root** (the folder that contains
> `Code/` and `prompts/`) — that's where your agent runs. Inside the architecture-session and
> template files under `templates/`, paths are instead relative to the docs hub
> (`architecture/…`, `overview.md`), but any reference that crosses repos — notably
> `prompts/STEP-index.md` — is always written in full. (See `METHOD.md` §7, "Path conventions in docs".)

## First action — kickoff or resume?
**Before doing anything else, decide which mode you're in** by reading the `PROJECT-STATUS`
marker near the top of `Code/{{PROJECT}}-docs/overview.md` (the `<!-- PROJECT-STATUS: … -->`
line). It has one of two values:

If `Code/{{PROJECT}}-docs/overview.md` does not exist, this is still the uninitialized
template/download; tell the user to run `./init.sh` first, then come back with *"Read
AGENTS.md and follow it."*

- **`not-started` → Kickoff mode.** The project hasn't been bootstrapped yet. **Begin the
  kickoff now without waiting to be asked**: read `Code/{{PROJECT}}-docs/BOOTSTRAP-PROMPT.md`
  and follow it from Stage 0. Greet the user briefly, ask their experience level, and — since
  `overview.md` is still the empty template — **draft the project brief with them in chat** (a
  couple of questions, then you write the first paragraph or two into
  `Code/{{PROJECT}}-docs/overview.md` for review; seed it from the one-line description in
  *What is {{PROJECT}}* below). The user should not have to pre-write `overview.md` or paste a
  kickoff command. The bootstrap flips the marker to `kickoff-complete` when it finishes.
- **`kickoff-complete` → Resume mode.** Kickoff already happened. **Do not re-run kickoff.**
  Pick up the next action via the next-action resolver (`METHOD.md` §10): **run
  `Code/{{PROJECT}}-docs/scripts/status.sh`** — it resolves §10 mechanically from disk and
  prints where you are, the next action, and the check-in cadence. Read
  `prompts/STEP-index.md` to confirm (and for the sub-STEP detail the script doesn't carry —
  the in-flight PLAN in `Upcoming Prompts/`), then tell the user what's next. If the script
  isn't available (older project, no shell), fall back to reading the index and applying §10
  yourself.

(If the marker is missing entirely — an older project predating it — fall back to inferring:
treat it as resume unless `prompts/STEP-index.md` is still the bare `init.sh` seed.)

## What is {{PROJECT}}
{{PROJECT_DESCRIPTION}}
<!-- Filled during kickoff from overview.md. Keep to a tight paragraph; details live in
     the architecture docs. -->

## How this project is built
This project follows the method in **`Code/{{PROJECT}}-docs/METHOD.md`** — read it. In short:
- Work is **Phase ▸ STEP ▸ substep**. Phase 1 is the MVP. STEP numbers are global.
- **STEP-1 is architecture-first**: design docs + ADRs, *no application code*.
- Durable docs live in `Code/{{PROJECT}}-docs/`:
  - `architecture/` — *what* the system is (versioned, living).
  - `adr/` — *why* it's that way (point-in-time decision records).
- The roadmap and status are in `prompts/STEP-index.md`.

## Architecture sessions  (how to run one)
When the user says **"run session N.M"** (e.g. *"run session 1.1"*), read the matching file
in `Code/{{PROJECT}}-docs/templates/architecture-sessions/NN-*.md` and follow it exactly:
interview the user one decision at a time, then write the output architecture doc and
update `prompts/STEP-index.md`. No copy-paste, no special commands.

**"run session N.M" is the user's go-ahead — begin in that same reply.** Don't acknowledge,
summarize the file, restate the plan, or ask whether to start (no "Ready when you are"). Read
`overview.md` and any earlier architecture docs silently, then immediately **ask the
session's first question**, calibrated to the recorded experience level. The user types one
short command and expects the first question back, not a confirmation prompt.

**Conditional sessions** are invoked **by name**, not by number: *"run the identity-auth
session"* → `conditional-identity-auth.md`; *"run the native-app session"* →
`conditional-native-app.md`; *"run the privacy session"* → `conditional-privacy-compliance.md`.
They're slotted into STEP-1 under a lettered substep (e.g.
`1.6a`, `1.7a`), so if the index's next open substep has a letter suffix, run the matching
`conditional-*.md` by topic rather than looking for a `NN-*.md` file for that number. Each
conditional has an owning session that decides it when the needed facts exist: Native app in
1.3, Privacy/compliance from Data Model / Security, and Identity/auth from Security. A
periodic check-in may also schedule a conditional later as a standalone
`Conditional session: <topic>` follow-up STEP; in that mode, read its active PLAN for the
exact invocation and output-doc number instead of reopening STEP-1.

Each session reads what it needs from disk (`Code/{{PROJECT}}-docs/overview.md` + earlier
architecture docs), so context can be cleared between sessions — state lives in files.

When STEP-1 is complete (the Cross-Cutting Review passed), the user moves into building by
saying **"run the planning session"** — read
`Code/{{PROJECT}}-docs/templates/planning-session.md` and follow it: it turns the locked
architecture into the Phase-1 implementation STEPs.

## Repos & workspace layout
This is a **multi-repo** project. The workspace root is **not** a repo — it's a per-machine
shell. (Mono-repo-for-now is the exception — then the root *is* the single repo and the
pointers are committed files; see `METHOD.md` §7.) The repos are siblings:
- `Code/{{PROJECT}}-docs/` — the docs hub (this repo). All durable content lives here.
- `prompts/` — `prompts/STEP-index.md` roadmap + archived STEP plans/substep prompts.
- `Code/{{PROJECT}}-*` — code repos, created as the architecture names them.

`registries/repos.yml` is the canonical inventory **and the index to the repos** — each
entry points to a repo whose **README is its "about"** (what it is, how to set it up; plus an
`ARCHITECTURE.md` if it has deep internals). **Before working in a repo, read its README
first** — the same way you read the architecture docs before a design change.
When creating an application-code repo, also apply the project-license posture recorded at
bootstrap by running
`Code/{{PROJECT}}-docs/scripts/apply-project-license.sh <new-repo-path>`. The authoritative
selection is in `Code/{{PROJECT}}-docs/.throughstone/project-license`; the helper validates
that selection against the docs hub's canonical `LICENSE`, copies the project license unchanged
for open-source projects, and creates no project `LICENSE` for proprietary projects. It also
copies `LICENSE-THROUGHSTONE` because the standard generated repo retains Throughstone-authored
README and CI scaffolding, and writes `LICENSING.md` to make those scopes explicit.
`scripts/setup-workspace.sh` sets up a new developer's machine (clones the siblings, writes
the root pointers).

**Workspace-root hygiene:** the workspace root should contain only per-machine pointers
and config (`CLAUDE.md`, `AGENTS.md`, `.claude/`), the repo folders (`Code/*`, `prompts/`),
and the `Upcoming Prompts/` working folder (scratch for the in-flight STEP). If you create
or find any *other* file at the workspace root, **ask whether it belongs in a repo** —
durable content almost always belongs in `Code/{{PROJECT}}-docs/`.

## Ground rules
- **Calibrate to the user's experience level.** Before asking user-facing questions or
  explaining a decision, read `Code/{{PROJECT}}-docs/overview.md` and use the recorded
  **Your experience level** value as the communication baseline. Keep `overview.md` as the
  single source of truth; don't duplicate the value into STEP plans or prompts.
- During the architecture STEP, produce **Markdown docs + ADRs only — no code**.
- Significant decisions become **ADRs** (`Code/{{PROJECT}}-docs/templates/adr.md`); never
  rewrite an accepted ADR's decision — supersede it or append an amendment.
- **Keep the docs true.** When implementation changes an architecture decision, update the
  affected `Code/{{PROJECT}}-docs/architecture/NN-*.md` and bump its Version Log, or write an
  ADR. New code counts too: a new component or repo may need the Architecture Overview
  architecture doc (`architecture/*-architecture-overview.md`) / `registries/repos.yml`, and
  a new domain term may need the Glossary architecture doc — don't let a doc go stale (see
  `Code/{{PROJECT}}-docs/METHOD.md` §6).
- **Keep accepted risks visible.** Known, accepted risks and deferred technical debt live in
  `Code/{{PROJECT}}-docs/registries/risks.yml`. Add or update a row when security controls,
  dependency fixes, incident follow-ups, or tech debt are consciously deferred. The register is
  an index: reference the architecture decision/section, ADR, issue/follow-up STEP, incident
  report, or check-in report that carries the details; create that source first if it doesn't
  exist.
- **Document code as you write it.** Every class, function, and method gets a docstring;
  comment the *why* of non-obvious logic (see
  `Code/{{PROJECT}}-docs/coding-standards/README.md`).
- **Suggest a check-in every ~10–20 STEPs.** When about that many STEPs have passed since the
  last check-in, proactively propose inserting a **Check-in STEP** that runs
  `Code/{{PROJECT}}-docs/runbooks/check-in.md` (doc-drift reconciliation both ways,
  conditional-session coverage, accepted-risk review, and a full test run). See `METHOD.md`
  §5.
- **Flag milestone docs at a phase/release.** When a phase completes or you cut a release,
  proactively ask the user about **release notes** and **user-facing doc updates** — neither
  is produced by normal STEP work. If the user wants release notes, start from
  `Code/{{PROJECT}}-docs/templates/release-notes.md`; end-user docs are otherwise outside this
  method's scope (see `METHOD.md` §5, *Milestone doc review*).
- **Never commit secrets.** Local dev values live in a gitignored `.env` / `.secrets/`;
  commit only a `.env.example` that documents the required keys.
- Keep **`prompts/STEP-index.md`** current — it's the source of truth for status.
- **Treat STEP-1 as the bootstrap special case.** `init.sh` seeds `STEP-1` as `Planned`; the
  kickoff creates the STEP-1 PLAN. When kickoff closes, flip `STEP-1` to `In progress` and use
  `step-0001-architecture` wherever branch-per-STEP applies.
- **Always say what's next.** End every session/STEP by updating the index, then tell the
  user the next action and to **start a fresh chat** for it. Answer *"what do I do next?"* by
  running `Code/{{PROJECT}}-docs/scripts/status.sh` — it runs the **next-action resolver**
  (`METHOD.md` §10) mechanically from disk (where you are · next action · check-in cadence) —
  then confirming against `prompts/STEP-index.md`. From disk, never from memory.
- One decision/question cluster at a time. Recommend defaults; flag what they foreclose.

## Working alongside others (humans or other agents)
Full conventions are in `Code/{{PROJECT}}-docs/runbooks/collaboration.md` — read it before any
STEP when more than one contributor is active. The rules that bind you as an agent:
- **One owner per STEP.** A STEP and all its substeps have a single owner — substeps aren't
  split across people. If work needs to split, make it separate STEPs.
- **Every STEP is worked on a branch** named `step-NNNN-short-name` — the same name in every
  repo it touches. Do this even solo.
- **Reserve the STEP number before working.** Pull `prompts/`, take `max + 1`, add the row to
  `prompts/STEP-index.md` **on `prompts/`'s shared trunk** (never a `step-NNNN` branch), then **commit
  and push immediately** (a dedicated `reserve STEP-N` commit) — before you branch or write. If
  the push is rejected, pull, renumber, push again. After any pull/merge — even a clean one,
  which merges two appended rows into a silent duplicate that no conflict flags — scan before
  pushing and renumber if it's non-empty:
  `grep -oE '^\|[[:space:]]*STEP-[0-9]+' prompts/STEP-index.md | grep -oE 'STEP-[0-9]+' | sort | uniq -d`.
- **Read the index first and warn on overlap.** The shared index row is the coordination
  surface. Before starting, compare the `Repos (projection)` of **in-flight** STEPs
  (`In progress`, plus any `Planned` row with a live `step-*` branch) against your scope; if
  they overlap, tell the user — then proceed (it's a heads-up, not a block). A *remote*
  `git ls-remote --heads origin 'step-*'` scan is an optional extra **only if** the team pushes
  its step branches — a local `git branch --list` never sees a teammate's branch.
- **Flip your STEP's row to `In progress` when you start** (right after cutting the branch) and
  **push the flip to the shared trunk** — reservation leaves it `Planned`, and a STEP left at
  `Planned` (or whose flip is unpushed) while you work is invisible to everyone else's overlap
  check.
- **Edit only your own rows** in shared table files (`prompts/STEP-index.md`, `adr/README.md`, phase
  `README.md`, `registries/repos.yml`); never re-sort or reflow them.
- **Significant decisions in a team land as `Proposed` ADRs**, accepted by the designated
  authority (see `adr/README.md`) — don't silently Accept a decision others depend on.
- **Reserve the ADR number like a STEP number.** The `adr/README.md` registry is shared, so
  two authors can append the same `ADR-NNNN` and git merges both into a silent duplicate. Pull,
  take `max + 1`, add the row and create the ADR file, then **commit and push immediately**;
  before every push (even a clean merge) scan with
  `grep -oE '^\|[[:space:]]*ADR-[0-9]+' adr/README.md | grep -oE 'ADR-[0-9]+' | sort | uniq -d`, and if it's non-empty or the push is
  rejected, recompute `max + 1`, renumber, and push again. See `runbooks/collaboration.md` §6.
