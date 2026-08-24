# Changelog

All notable changes to Throughstone are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions here
refer to the **Throughstone scaffold** (the method, templates, runbooks, and tooling), not to
any project built with it.

## [Unreleased]

> **Withdrawn (2026-08-19).** Work on how the method treats a repository it did **not** create —
> whether it applies a license, whether it stamps or augments a README, whether it installs CI, and
> where it records what it found — was developed on `main` between 2026-08-15 and 2026-08-19 and has
> been backed out. It was being built without a settled design, so it is being re-planned as its own
> piece of work and will return in a later release. If you cloned `main` during that window, your
> copy carries an unfinished version of it. **No tagged release was affected**; the latest release
> remains v1.7.1.

### Added
- **A runbook for splitting a repository** — `runbooks/splitting-repos.md`. The method used to say
  splitting was "standard git," which is not something you can act on: the recipe you find
  elsewhere makes the extracted repo *new*, with its history rewritten by `git filter-repo`, a
  tool that never ships with git and needs Python on every install route. The runbook writes down
  a different mechanic — clone the whole repo and delete forward — so nothing is rewritten, both
  sides keep the full history, and `git blame`, `git log --follow` and every commit SHA your
  project has recorded keep working in the new repo on day one. It covers both cases behind one
  routing block: splitting a code repo in two, and converting a mono-repo-for-now workspace to
  multi-repo. It asks three questions before you start and the rest at the step that needs them;
  every one but the mapping itself has a default, so answering "use your judgement" still produces
  a correct split. The one real cost is stated plainly in the file: every new repo inherits every
  blob the origin ever committed, including deleted ones, and an appendix covers purging first when
  that matters.
  Split-out repos can now record where they came from, in a `provenance:` block on their
  `registries/repos.yml` row.

  Shipping with it: **the rule telling you to split before adding a second contributor is gone.**
  It gave two reasons and neither survived. The STEP-number push-race works exactly the same in a
  mono repo with a shared remote — what a team needs is shared remotes, not several of them — and
  the overlap warning's mono fallback was already written, in the very section that clause cited.
  How many repos you have follows your architecture, not your headcount. The solo-to-team section
  of `runbooks/collaboration.md` now has a mono path of its own, including the warning not to run
  `scripts/setup-workspace.sh` in a mono clone; `METHOD.md` §7 and `prompts/README.md` moved with
  it, the first gaining the mono→multi special case (that STEP is branchless, and its number is
  reserved on trunk) and the second generalizing its thin-STEP note from the check-in alone to two
  families.
- **Repo rows record who owns each repo and what it already provides.** `registries/repos.yml`
  gains three per-row fields. **`origin:`** (`created` | `adopted`) says whether Throughstone made
  the repo or took on one that was already there — a fact, written once when the repo is
  registered, that never changes. **`control:`** (`managed` | `external`) says whether Throughstone
  may write into that repo: `managed` is a standing permission, asked once per repository and never
  per file, while `external` means the repo is recorded and referenced in full and never written
  into. Control is a state that changes over time rather than a fact about who created the repo, so
  a repo the method built can be handed over and a repo it never built can be placed under its
  care. **A missing `control:` reads as `external`**, because control is a permission and an
  unanswered permission is not granted — the repo is recorded, and nothing is written into it until
  somebody answers. **`provides:`** records how each of the three things a repo needs — a README, a
  stated licensing posture, a described CI gate — is actually met there, as a status (`ours`,
  `extended`, `theirs`, `N/A`, `gap`) and a note; `gap` and `N/A` must say why. It goes only on
  rows whose `location` is a repository, and never on a row the setup script seeds — a status
  written before anyone had looked at the repo would be a guess rather than a record. Two
  invariants hold across the pair: a `managed` repo has no `gap` — either the need is met, or the
  repo is `external` — and an `external` repo has no `ours` and no `extended`. The registry's
  header carries the whole schema, the default, and the five rules anything reading or rewriting
  that file has to follow, because it is read by scripts that match line prefixes and do not parse
  YAML. `mono` joins the `type:` enum for the workspace root of a mono-repo-for-now project.
  Existing rows are not rewritten — `UPDATING-THROUGHSTONE.md`'s 1.8 section covers adding the
  fields to a project you already have.

### Changed
- **The interactive setup no longer licenses your project open source by default.** `init.sh` asks
  whether the project is open source or private/proprietary, and that question used to default to
  open source, with the license question after it defaulting to MIT — so two bare Enters granted
  everyone an irrevocable license to the project's code without the user ever naming one. The
  project-type question now defaults to **private / proprietary**, which writes no project
  `LICENSE` at all and leaves the decision to be made deliberately later. The open-source
  sub-question keeps its MIT default: by the time it is asked, open source is an explicit choice.
  Nothing changes for `--license=…` or `--non-interactive`, which have always required the posture
  to be stated. Existing projects are unaffected — their posture is already recorded in
  `.throughstone/project-license`.
- **The README and website now tell you to clone the latest *release*, not `main`.**
  `git clone --branch v1.7.1 …` gives you the 1.7 release; `main` is where Throughstone itself is
  built and can carry unfinished work. The "Use this template" path is flagged as unable to be
  pinned to a release, since GitHub always copies the default branch.
- **A session template's go-ahead now fires on being *invoked*, not on being *read*.** Every
  `templates/architecture-sessions/*.md` closed with "Begin now — in this same reply", which treated
  the act of opening the file as the user's go-ahead. But session files are read by more than the
  agent running the session: the Cross-Cutting Review enumerates every conditional to check
  applicability, the periodic check-in re-evaluates them, and a reader that only wants a session's
  work list has no business starting an interview. The paragraph now opens **"If you were sent here
  to run this session…"** and closes by releasing a reader who wasn't — same behavior when a session
  is actually invoked, no reliance on the reader's own framing to resist the instruction otherwise.
- **One work-list heading across every session template.** `13-glossary.md` used "What to produce
  (work through these)" and `14-cross-cutting-review.md` used "What to check"; both now use
  **`## Decisions to make (in order)`**, like the other fifteen, with a note under the heading saying
  what that session's items actually are (term batches; checks that may surface a decision). Anything
  reading a session file now finds the work list under one name instead of learning a per-file name.
  `METHOD.md` §4 records the skeleton as part of the contract for adding a session, and a new
  maintainer test enforces it.

### Fixed
- **`init.sh` could destroy a repository it was run inside.** Unpacking the template into a
  repository you already had — the natural thing to try when you want Throughstone in a project
  that exists — and running `./init.sh` there deleted that repository's `.git` outright, every
  commit with it, at exit code 0 and with no warning. Your working files survived; your repository
  did not. The bootstrap is one-time and destructive by design — it removes the template's own git
  history and every template-only file — so it now establishes that it is looking at a fresh
  template checkout *before* it removes anything, and refuses with an explanation when it is not.
  The marker in the root pointers cannot answer that on its own, because an unpacked template
  brings those files along with it, so git is asked too — and only when there is a `.git` in the
  folder to lose. A checkout counts as fresh when its committed history is the template's own and
  it tracks nothing the template does not ship, or when it has no commits, no branches and nothing
  staged. Every documented setup route still works untouched: a fresh unpacked download, a clone of
  a release tag, a "Use this template" repo, and `git init` beside the template to attach an empty
  origin. Covered by `tests/init-fresh-template-guard.sh`, which derives the template's root-entry
  list from the template itself so the check cannot go stale.
- **A generated repo's ignore file named one per-machine agent file instead of matching the family.**
  Every repo `init.sh` creates ignored `.claude/settings.local.json` exactly, so an editor's lock or
  autosave sibling (`#settings.local.json#`, `settings.local.json~`) — per-machine files, all of
  them — was left untracked and swept in by a `git add -A`. Throughstone's own repository moved off
  the by-name rule for this reason and the generated one did not follow. Now matched by pattern.
  Shared project config (`.claude/settings.json`) is still committed, so this narrows what leaks
  without narrowing what a team can share.
- **`init.sh`'s closing backup tip was wrong for a mono-repo project.** It told every project to
  "create empty repos on your host, add their URLs to `registries/repos.yml`, and push each local
  repo's `main` branch" — which is what `runbooks/collaboration.md` §9 expressly tells a mono
  project *not* to do, since those rows describe folders inside the one repo rather than repos to
  clone. The tip is now layout-conditional: mono is told to create one repo, push the root repo's
  trunk, and leave the registry rows alone. The mono + team kickoff note stopped citing the
  repealed split-before-a-teammate rule in the same change — the observation under it still holds
  and is still printed, but it now points at the fallback `collaboration.md` §4 prescribes rather
  than telling you to split.
- **`11-interface-contracts.md` punctuation drift.** Its go-ahead paragraph had ASCII hyphens where
  every sibling file had em dashes — identical wording otherwise. Now byte-identical to the rest.
- **Lifting a document into `architecture/` could fail the check that guards it.**
  `inputs/README.md` told you to add the `Version` / `Status` header when lifting a spec or finished
  design doc, but omitted the **Version Log** — which `scripts/check.sh` check 4 requires of every
  numbered architecture doc, and which a document written outside the method almost never arrives
  with. All three fields are now named at the point of the lift.
- **The STEP index's status legend didn't mention `N/A`.** A substep whose area structurally doesn't
  apply (the UI session on an API-only system) is marked `N/A` — accepted by `check.sh` and skipped
  by the next-action resolver — but the legend listed only the five STEP states, so the one place a
  reader checks before writing a status didn't describe a value the file legitimately contains.
- **A `Coverage:` line could be a bare word that told a later reader nothing.** The field records
  that a doc deliberately describes only part of its area, and every check-in resurfaces it for a
  decision — but `METHOD.md` §6 and the architecture doc template both showed it as a lone token
  (`deferred`), so the reader who meets it months later can't tell whether the gap blocks them, and
  the check-in has nothing to weigh. Both now require one sentence: what is missing, how big it is,
  and what it means for someone building on the doc, written as an ordinary bold header field
  (`**Coverage:** deferred — …`).
- **The deferred-coverage sweep looked for a string the docs don't contain.** `runbooks/check-in.md`
  told the check-in to enumerate architecture docs "carrying `Coverage: deferred`" — but the field is
  written like every other header field, so the literal phrase never appears, and now that its value
  is a sentence it is further still from matching. The sweep now reads the `Coverage:` **field** and
  takes anything other than `full`, which is what stops a deferral from quietly becoming permanent.

## [1.7.1] - 2026-08-10

A small follow-up that gives the **`inputs/` folder** (added in 1.7.0) a lifecycle, so brought-in
documents don't quietly go stale as the generated `architecture/` docs supersede them.
Greenfield-inert: a fresh project ships an empty ledger and behaves exactly as before.

### Added
- **Inputs index** (`Code/{{PROJECT}}-docs/inputs/inputs-index.md`) — a ledger that records, per
  input, which parts a generated `architecture/` / `adr/` doc has superseded and which still hold
  (section-level where the input's structure allows, whole-doc otherwise). It is written when an
  input is imported and when a session captures its content.
- **`inputs/archive/` retirement** — a fully-superseded input is *moved* there (a move, never an
  edit or a delete); sessions read `inputs/` but not `inputs/archive/`, so a captured document stops
  reading as current intent while it is kept for history.
- **Check-in inputs sweep** — the periodic check-in reconciles the ledger against the architecture
  docs, surfaces a newly-superseded input for a retire/keep decision (never auto-moving), and
  records the outcome in the check-in report.

### Changed
- **Inputs are point-in-time; `architecture/` is the living truth.** Where a generated
  `architecture/` or `adr/` doc covers the same ground as an input, the generated doc wins.
  Architecture-grade inputs are lifted into `architecture/` promptly — a PRD synthesized, a
  protocol/API spec or other finished doc copied or lightly reformatted — rather than left living in
  `inputs/`. The system-overview, architecture-overview, substep, and implementation-planning
  reminders now read live inputs (not `inputs/archive/`) and treat them as a starting point, not
  current truth.

## [1.7.0] - 2026-08-10

A **base-refactor** release that generalizes the method. It
removes assumptions baked in for brand-new, MVP-first projects, so the method also fits later
phases, re-runs, custom conventions, and existing codebases. **Two opt-outable default shifts**
(the doc-maturity ladder and the check-in cadence); nothing existing is force-migrated.

### Added
- Optional **`Coverage:`** field on architecture docs (`full` / `deferred` / `enumerated to
  depth N`) — records a deliberately partial area without abusing `Status`.
- **`inputs/` folder** (`Code/{{PROJECT}}-docs/inputs/`) — a durable home for documents *you*
  provide that inform the design: product specs / PRDs, prior or external architecture/design
  docs, protocol/API specifications, UI designs and mockups, prior-art research. The kickoff and
  every architecture session read the relevant inputs and build on them instead of re-deriving
  what you already know; a document handed to the agent in chat is saved into `inputs/` so it
  persists across the fresh-chat-per-session model. Not STEP-1-only — later phases and check-ins
  can add to it, and the implementation planning session and substep template point at it too.

### Changed
- **Method version → 1.0** (from `0.4 (beta)`): with the base-refactor generalizations in this
  release, the core method graduates from beta; the collaboration and scaffold-update layers keep
  maturing.
- **Architecture-doc metadata decoupled** into three independent header facts: **`Version`**
  (identity; `major` = a breaking architectural change, no longer a maturity "era", so a house
  version scheme is fine), **`Status`** (maturity), and optional **`Coverage`** (completeness).
  The **doc-maturity ladder is redefined `Draft → Current → Deprecated`**, retiring the `MVP` and
  `Stable` rungs; the periodic check-in no longer reconciles `Status: Deprecated` docs.
- **Periodic check-in resurfaces deferred coverage:** the check-in now runs a **deferred-coverage
  sweep** — every non-`Deprecated` architecture doc carrying `Coverage: deferred` gets an explicit
  disposition each check-in (backfill now / still defer / seed a `Planned` backfill STEP + a
  tracked `risks.yml` risk), and a thin architecture-only STEP finishes the doc when it's time. A
  `Deprecated` deferred doc is listed as retired, never backfilled. Greenfield-invisible unless a
  doc marks `Coverage: deferred`.
- **Phase 1 is a chosen first milestone, not always an MVP:** Phase 1 is now defined as *the first
  release-level milestone*, with its kind chosen at kickoff — **MVP / POC / prototype / v1**, MVP
  recommended but no longer assumed. The chosen name drives both the phase label
  (`## Phase 1 — <name>`) and the phase folder (`prompts/001-<phase-name>/`). The pre-named
  `prompts/001-mvp/` folder is **no longer shipped** — the phase folder is created at STEP-1
  archive time from the index heading's name (an MVP archives to `001-mvp/`, a POC to `001-poc/`),
  with no `status.sh` / `check.sh` change (they key on index rows, not folder names). Greenfield
  that takes the MVP suggestion is byte-identical; kickoff now asks one question instead of
  assuming.
- **Release/launch stage is a recorded project fact:** the method now separates a project's
  **release stage** — how widely and to whom the system ships (pre-launch → internal → closed /
  public beta → GA) — from Phase-1 *scope* (MVP / POC / v1) and doc *maturity* (Draft / Current /
  Deprecated); the three no longer collapse into "MVP." `overview.md` gains an optional **Release
  stage / launch target** line and kickoff asks it (leading with a pre-launch default). Architecture
  sessions now calibrate their **breadth** defaults (how big / how public) to the recorded stage +
  load and their **rigor** (security, privacy, availability) to blast radius / data sensitivity,
  instead of an assumed "MVP" — an early stage is never a license to lower rigor on a high-stakes
  system. Additive and opt-outable: the decisions and recommendations are unchanged if you take the
  default, and `check.sh` never reads the line. No `status.sh` / `check.sh` / STEP-grammar change.
- **Planning session scaffolds only unregistered repos:** the implementation planning session's
  repo-scaffolding work-item is now **existence-aware** — it scaffolds each repo the architecture
  names only if that repo isn't already registered in `registries/repos.yml` with a filled-in README;
  an already-registered repo is **left in place, not re-created**. It degrades gracefully when
  `repos.yml` is absent or has no code-repo rows (a mono-repo, or a greenfield first run) — nothing is
  registered, so every named repo scaffolds exactly as before. Because it keys on the repo's actual
  state (is it already registered?) rather than how the project began, it also stops a planning
  **re-run** from proposing to re-scaffold an existing repo. Greenfield
  first run is byte-identical; no `status.sh` / `check.sh` / STEP-grammar change.
- **Planning STEP-shape is milestone-relative:** the implementation planning session's STEP sequence
  is no longer written build-from-scratch. It now plans to **build or extend what the milestone needs,
  in dependency order, given what already exists** — scaffolding and the core data layer come first
  only when they don't exist yet (a first run), with the scaffold → data → capabilities → integration
  sequence kept as the worked example for that case; a re-run or a later phase starts from what's built
  and extends it. Like the existence-aware scaffolding above it keys on observable state (what's
  already built), so it also fixes a latent greenfield **re-run / later-phase** case where the old
  shape read as rebuild-from-scratch. Greenfield first run is byte-identical (nothing built → the same
  scaffold-first outline); no `status.sh` / `check.sh` / STEP-grammar change.
- **Planning session targets the first uncompleted phase:** the implementation planning session now
  plans **the first uncompleted phase** — the lowest-numbered roadmap phase whose STEPs aren't all
  complete (read from `prompts/STEP-index.md` + the Phasing & Roadmap doc) — instead of always
  **Phase 1**, defaulting to Phase 1 on the first run. On a later phase or a re-run it reads *that*
  phase's scope and outlines *its* STEPs, rather than being told to pull "Phase 1." Like the two
  planning-session changes above it keys on observable state (which phase is done), so it also fixes a
  latent greenfield **later-phase** case. Greenfield first run is byte-identical (the first uncompleted
  phase is Phase 1 → the same outline); no `status.sh` / `check.sh` / STEP-grammar change.
- **Check-in cadence is a project-selectable default:** the check-in rhythm — how often the roadmap
  interleaves a **Check-in STEP** — was a hardwired 10–20 STEP window (`status.sh` flagged DUE at 10,
  OVERDUE at 20). It is now a **project-selectable number N**, recommended **20**, recorded as an
  optional `<!-- CHECK-IN-CADENCE: N -->` line in `overview.md`; `status.sh` reads it (defaulting to 20
  when the line is absent) and flags a heads-up (DUE) at `N-5` and OVERDUE at `N+5`. This **deliberately
  recenters the default** notice window from DUE 10 / OVERDUE 20 onto the target 20 (→ **DUE 15 /
  OVERDUE 25**) — one of the two opt-outable default shifts noted above. Nothing is lost: 15 reproduces
  the previous window (DUE 10 / OVERDUE 20) and any rhythm is one number away (50 → DUE 45 / OVERDUE 55).
  The cadence stays a judgment-based guideline — only the default notice/overdue thresholds move, and
  the human still places each check-in at a sensible breakpoint. `check.sh` warns (never fails) if the
  marker is present but not a positive integer; no `status.sh` failure path and no STEP-grammar change.
- **Workspace model accepts a repo registered in place:** a repo may be registered in
  `registries/repos.yml` by a **`location:` outside the `Code/*` sibling shell** — an absolute or
  otherwise arbitrary path — so a repo that lives elsewhere is referenced where it sits instead of
  created as a `Code/*` sibling. `scripts/setup-workspace.sh` already honors `location:` verbatim
  (cloning from `remote:` into it, or referencing the repo in place when there's no remote), so this
  is a documentation clarification with no tooling change; branch-per-STEP and the overlap warning key
  on repo identity, not location, so an in-place repo participates unchanged. The `Code/*` sibling
  layout stays the default and greenfield is byte-unchanged.

## [1.6.0] - 2026-07-09

A **release-readiness and operational discipline** release: it adds a structured security
review framework, durable report artifacts, stronger STEP/test planning gates, better setup
tooling, and more approachable onboarding material for new Throughstone projects.

### Added
- **Security review framework** for generated projects: S0 Security Baseline, S1 Security
  Sweep, and S2 Security Audit runbooks/checklists; `registries/security-reviews.yml` for
  review cadence and change markers; and report templates for baseline, sweep, and audit
  outputs.
- **Durable reports structure** under `reports/` for check-in reports, incident postmortems,
  security reviews, and test-result summaries.
- **Test results summary template** for recording test, coverage, CI, and quality-gate
  outcomes.
- **Generated project onboarding guide** to help new contributors understand the scaffolded
  project structure and workflow.
- **`doctor.sh` dispatcher** with a single entry point for `status`, `check`, and `links`.
- **Local Markdown link checker** for durable Throughstone documentation.
- **Website publishing workflow/checks** and artifact-trail publication support.
- **Video resources** in the README covering setup, early sessions, conditional sessions,
  scaling, observability, glossary, post-architecture files, and STEP creation.

### Changed
- `METHOD.md` is now **Method version 0.4 (beta)**.
- STEP plans now require an explicit **test plan** for code-changing work, including test tier,
  run timing, command/gate, and substep coverage.
- The method now more clearly distinguishes small normal changes from work that should become a
  full STEP.
- Check-in guidance now records durable reports under `reports/` instead of burying review
  artifacts inside STEP folders.
- Incident postmortem handling is standardized around report templates and stable report paths.
- Security-sensitive work now points to the Security & Threat Model and risk register, while
  reserving S0/S1/S2 materials for explicit security review STEPs.
- Conditional sessions are more robustly documented, rechecked, and prioritized when discovered
  after STEP-1.
- README and site copy now explain Throughstone's fit, limits, AI-project positioning, setup,
  and workflow more clearly.
- Template filenames are normalized with explicit `*-template.md` naming where appropriate.

### Fixed
- `init.sh` now validates and propagates project license choices more reliably.
- Generated projects can choose a configurable trunk branch instead of assuming `main`.
- Mono-repo setup avoids reusing non-empty template-created origins unsafely.
- Bootstrap remote setup supports manual/non-GitHub Git hosts more clearly.
- ADR authority substitution is explicit and covered by regression tests.
- `status.sh` prioritizes late conditional-session follow-up STEPs correctly.
- Local documentation links are now mechanically checkable through `doctor.sh links`.

## [1.5.0] - 2026-06-06

A **risk visibility and release-notes workflow** release: it adds a canonical accepted risk /
technical debt register, introduces a reusable release-notes template, and tightens the
architecture-session flow around consciously deferred work before the release is merged or
tagged.

### Added
- **Accepted risk and technical debt register** (`registries/risks.yml`): a compact,
  machine-readable index for known accepted risks and deferred technical debt, with each row
  pointing to the durable source artifact that carries the full context.
- **Release notes template** (`templates/release-notes-template.md`): a lightweight milestone artifact
  focused on user-visible changes, action required, known issues, documentation, and technical
  references.
- Method and agent guidance requiring accepted risks to stay visible, with a source architecture
  section, ADR, issue/follow-up STEP, incident report, or check-in report created or referenced
  before a risk-register row is added.

### Changed
- `METHOD.md` is now **Method version 0.3 (beta)**.
- Conditional architecture sessions now record **Include**, **Deferred**, or **N/A** with a reason
  and revisit trigger.
- Conditional-session ownership is clearer: Native app is decided by Architecture Overview,
  Privacy/compliance by Data Model or Security, and Identity/auth by Security.
- STEP-1 bootstrap behavior is documented as a special case: `init.sh` reserves STEP-1, kickoff
  creates the STEP-1 PLAN, then flips it to `In progress` and uses `step-0001-architecture`
  wherever branch-per-STEP applies.
- Release/deploy and milestone-doc guidance now points agents to the release-notes template while
  keeping user-facing documentation optional and explicit.
- STEP index path wording now distinguishes workspace-root paths from docs-hub-relative paths.

### Fixed
- `status.sh` now stops resolving STEP-1 when a substep has an unrecognized status or when no
  runnable open substep can be derived.
- Malformed STEP-index state now points users toward `scripts/check.sh` instead of silently
  skipping ahead.

## [1.4.0] - 2026-06-03

A **scaffold-update process** release: it replaces the old "hand-copy upstream improvements"
guidance with a conservative update model for bootstrapped projects, and tightens bootstrap
and resume behavior before cutting the next tag.

### Added
- **Throughstone scaffold update guide** (`UPDATING-THROUGHSTONE.md`): an
  advisory-first process for comparing a project to a newer Throughstone release, classifying
  files by bucket, reporting risk/implications, and applying only reviewed scaffold/process
  changes.
- **Manifest + catalog model** for future updater tooling: project state would live in
  `Code/{{PROJECT}}-docs/.throughstone/manifest.yml`; release implications would live in an
  upstream update catalog; the updater itself stays stateless.
- **Three-way comparison rules** (`base` / `local` / `upstream`) and classifications:
  already-current, upstream-only, local-only, diverged, untracked, protected, and
  manifest-invalid, with baseline-unknown handling for projects that lack a trustworthy
  install-time manifest.
- **Mechanical risk signals** for updater reports, including script changes, git/remote-touching
  commands, CI changes, placeholder handling, status resolver changes, incomplete update groups,
  and dirty affected repos.

### Changed
- `METHOD.md` is now **Method version 0.2 (beta)** and points scaffold updates to the new
  guide instead of suggesting direct hand-copying.
- The docs hub and template README now make clear that Throughstone improvements do not apply
  automatically after bootstrap, project-owned state is protected, and even script updates need
  review.
- STEP plans and substep prompts now remind agents to calibrate implementation work to the
  user's recorded experience level, not only architecture-session interviews.
- README and website quickstarts now lead with the direct clone flow and clarify GitHub template
  setup.

### Fixed
- `status.sh` now ignores HTML-commented example STEP rows so the next-action resolver does not
  treat documentation examples as real roadmap state.
- Bootstrap no longer leaves Throughstone's root README and changelog in generated projects.
- Mono-repo bootstrap now reuses a non-Throughstone root `origin`, while multi-repo workspaces
  remain detached until the user chooses remotes.
- Successful bootstrap remotes are recorded in `repos.yml` so `setup-workspace.sh` can clone
  sibling repos later.
- The method-check workflow can locate `check.sh` in both multi-repo and mono-repo layouts.
- Session 1.1's conditional-session summary includes privacy/compliance alongside native app
  and identity/auth.

## [1.3.0] - 2026-06-01

A **coding-standards** release: it reframes the shipped standards as customizable starting
points, broadens per-language coverage (adds Java and C#, plus concurrency/async and Python
idioms), and introduces three cross-cutting standards — SQL, Shell, and API design — wired into
the method so each surfaces at the right moment.

### New cross-cutting standards
- **SQL** (`coding-standards/sql.md`): naming, formatting (sqlfluff), query practices,
  parameterized-query safety, schema/DDL, and migrations — secondary to the language docs where
  they conflict.
- **Shell / Bash** (`coding-standards/shell.md`): strict mode, quoting/safety, naming/layout,
  idioms, and error handling (Google Shell Style Guide + ShellCheck/shfmt); the shebang is
  framed as an explicit, recorded project decision.
- **API design** (`coding-standards/api.md`): an opinionated, customizable house style for
  REST/HTTP APIs — resource naming, methods/status codes, RFC 3339 UTC timestamps, money as
  integer minor units, RFC 9457 problem-details errors, idempotency, and rate limits — with
  three per-project forks flagged (field casing, pagination, versioning), each with an ADR
  pointer. Complements each API's versioned interface contract artifact from the Interface Contracts session.

### Expanded per-language coverage
- **Java** (`java.md`) and **C#** (`csharp.md`) standards added.
- **Concurrency / async** sections added to Python, Rust, and TypeScript.
- **Python**: a Language idioms section.

### Customizable by default
- Shipped standards reframed as **customizable starting-point drafts** — both the per-language
  headers and the README — so teams treat them as a draft to edit, not law to obey.
- The **all-languages documentation rule** broadened to **fields/properties** (docstrings where
  the language documents them, e.g. Java fields, C# properties), public and private.

### Wiring
- The cross-cutting standards are reconciled by the **Test Strategy session** and recorded in
  the Test Strategy architecture doc (kept only when each applies — a relational DB for SQL,
  shell scripts for Shell, an HTTP/REST boundary for API), listed in `coding-standards/README.md`
  and the `METHOD.md` hub gloss ("per-language plus cross-cutting"), and
  `templates/substep-prompt-template.md` nudges API-touching substeps to read `api.md`.

## [1.2.0] - 2026-06-01

A **discoverability & docs-hygiene** release: it indexes the runbook and registry folders, adds
the **secrets-rotation runbook** the operate-time set was missing, makes the **session set
flexible** for added/conditional sessions, and closes plain-language gaps the method's own L1/L2
standard exposed.

### New operate-time runbook
- **Secrets rotation** (`runbooks/secrets-rotation.md`): scheduled rotation (inventory, cadence,
  no-downtime overlap, verify-then-revoke) and a **revoke-first** response to a suspected leak
  that hands off to the incident runbook. Operationalizes the secrets & data protection posture
  from the Security & Threat Model architecture doc, mirroring how the dependency runbook
  operationalizes the dependency-risk posture.

### Discoverability & docs hygiene
- **README indexes** for `runbooks/` (all five — purpose, when each fires + trigger phrase,
  governing section; STEP-shaped vs. operational) and `registries/` (machine-readable state,
  pointing at `repos.yml`'s own header rather than duplicating the schema); docs-hub rows now link
  both indexes.
- **Conditional-session naming is shown, not just described:** the by-name → file mapping inline
  in METHOD §4, and a copyable lettered-row example in the STEP-index seed.
- **Plain-language glosses** for jargon flagged against the method's own L1/L2 standard:
  API / OpenAPI / GraphQL / protobuf (session 1.3) and the RPO/RTO acronyms (session 1.8).

### Flexible session set
- **Session numbering no longer hardcodes the current set:** the conditional-doc rule and
  `status.sh` review-detection adapt to added sessions; dependency-bearing sessions
  (Scaling & Performance, UI / Design System, Infrastructure & Deployment, Observability,
  Interface Contracts, and Test Strategy) read relevant conditional docs when present.
- **Glossary session** harvests terms from every architecture doc (including conditional docs above
  the core block), not a fixed range.
- **METHOD §4 "Adding a session" recipe** — conditional (zero-touch) vs. standard (renumber the
  Cross-Cutting Review) wire-in checklist.

## [1.1.0] - 2026-05-31

This release **broadens the architecture sessions**, adds the **operate-time runbooks** the
method was missing, and introduces a **mechanical tooling layer** (scripts + CI) that enforces
rules the method previously trusted to discipline.

### Broader architecture coverage
- **Resilience & disaster recovery** is now first-class in the Infrastructure & Deployment
  session (1.8):
  failure modes / single points of failure, an availability target, graceful degradation, and
  backups with RPO/RTO and restore-rehearsal.
- **Accessibility & internationalization** in the UI / Design System session (1.7): a concrete a11y target
  (WCAG 2.1 AA) plus a new i18n/l10n decision in the don't-foreclose spirit.
- **New conditional session — Privacy, compliance & data governance** for projects handling
  personal/regulated data (applicable regimes, data inventory, lawful basis/consent,
  retention/deletion, data-subject rights, residency & sub-processors).

### Stronger process discipline
- **Explicit conditional-session selection:** the kickoff now records a *Conditional sessions
  considered* table (Include / N-A + reason), so a skipped conditional is a deliberate, recorded
  choice — never a silent omission.
- **Milestone doc review:** at each phase/release the agent proactively raises release notes and
  end-user docs.
- **Documentation discipline** strengthened across the method; **testing guidance** sharpened
  (~80% coverage suggestion, per-step/substep test defaults).

### New operate-time runbooks
- **Release / Deploy / Rollback** — a rollback plan before you deploy, reversible migrations,
  staging-first, a post-deploy watch window.
- **Incident Response & Postmortem** — stabilize, then open an Incident STEP (RCA → find similar
  → fix & harden).
- **Dependencies & Supply Chain** — vet before adding (license / provenance / pin) and audit on
  the check-in cadence (vuln scan, lockfile hygiene, SBOM).

### Mechanical tooling (new)
- **`scripts/check.sh` — the "doctor":** flags *and suggests a fix for* duplicate STEP/ADR
  numbers, invalid statuses, missing architecture-doc frontmatter, and ADR registry/disk drift.
  Read-only; runnable in CI.
- **`scripts/status.sh` — next-action resolver:** prints "where you are · next action · check-in
  cadence" straight from disk; a resuming agent now runs it as its first action.
- **GitHub Actions CI starter:** a live method-integrity workflow (runs `check.sh`) plus a
  per-repo test-gate template.

### Other
- Maintainer contact moved to **hershey@throughstone.org**.
- A thin pointer **README at the docs-hub root**.

## [1.0.0] - 2026-05-31

Initial public release of the Throughstone scaffold — a starting structure for building
software **architecture-first** with an AI coding agent.

### Added
- **The method** (`METHOD.md`): the Phase → STEP → substep structure, architecture-first STEP-1
  (design docs + ADRs, no code), the two durable doc genres (architecture docs + ADRs),
  doc versioning, and the disk-derived next-action resolver.
- **Architecture sessions:** 13 core sessions (System Overview, Requirements & Non-Goals through Cross-Cutting Review)
  plus 2 conditional sessions (native app, identity & auth).
- **Runbooks:** the periodic check-in and multi-developer/agent collaboration.
- **Templates:** architecture docs, ADRs, STEP plans, substep prompts, repo READMEs, per-language
  coding standards, and the kickoff bootstrap.
- **Setup tooling:** the `init.sh` wizard and `setup-workspace.sh`; multi-repo and
  mono-repo-for-now layouts; license selection and stamping.
- **Brand assets** and the throughstone.org documentation site.

[1.7.1]: https://github.com/mherschberg/Throughstone/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/mherschberg/Throughstone/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/mherschberg/Throughstone/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/mherschberg/Throughstone/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/mherschberg/Throughstone/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/mherschberg/Throughstone/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/mherschberg/Throughstone/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/mherschberg/Throughstone/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/mherschberg/Throughstone/releases/tag/v1.0.0
