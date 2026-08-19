# Updating Throughstone

Use this when you want to compare a bootstrapped project against a newer Throughstone
template release and decide whether to bring over scaffold improvements.

Trigger phrases:
- "check for Throughstone updates"
- "update the scaffold"
- "compare this project to the latest Throughstone template"

This is **scaffold/method maintenance**, not a created-project runbook. Runbooks cover the
project you are building; this file covers the Throughstone machinery copied into that
project. If an update changes method rules, agent behavior, collaboration rules, CI, or
multiple repos, turn it into a tracked STEP before applying it.

## 1. Principles

- **Default to advisory.** The first action is always a report, not a write.
- **Do not treat unchanged-local as safe.** It only means the file can be replaced without a
  text merge; the behavioral risk may still be high.
- **Project state is protected.** Never automatically update architecture docs, ADRs,
  project overview, STEP history, application code, or stamped/generated repo files.
- **The updater is stateless.** If updater tooling exists, project state lives in a manifest
  in the docs hub; update logic may change upstream, but it must read state from disk.
- **Do not run surprise remote code.** Manual comparison does not require signatures or
  checksums. If future tooling executes downloaded updater code, pin the release/ref and verify
  it using the provenance mechanism that release publishes.
- **Make rollback boring.** Apply updates only when every affected repo has a clean working
  tree and index, use the branch required by this guide, and keep the report with the change.

## 2. File Buckets

| Bucket | Examples | Update policy |
|--------|----------|---------------|
| **Tools / scripts** | `scripts/status.sh`, `scripts/check.sh`, `scripts/setup-workspace.sh` | Review required. May be replaced when local still matches the installed baseline, but still report behavioral implications. |
| **Process docs** | `METHOD.md`, `AGENTS.md`, `UPDATING-THROUGHSTONE.md`, `prompts/README.md`, `runbooks/*.md`, `coding-standards/*.md` | Review required. Changes may alter how contributors or agents work. Apply as a coherent group when files reference each other. |
| **Templates for future use** | `templates/*.md`, `templates/architecture-sessions/*.md`, `templates/ci/*.yml` | Future-only by default. Updating them affects newly generated docs/sessions/repos; it does not rewrite existing generated outputs. |
| **Stamped/generated files** | repo `README.md`, copied CI workflows, `.env.example`, STEP plans | Project-owned after creation. Never auto-update; provide advisory diffs only if explicitly requested. |
| **Project state** | `overview.md`, `architecture/`, `adr/`, `prompts/STEP-index.md`, `prompts/<phase>/`, application code repos | Never auto-update from upstream Throughstone. Changes happen through the normal method: sessions, ADRs, STEPs, and check-ins. |

`prompts/README.md` is the exception inside `prompts/`: it is scaffold/process guidance for
future STEP authoring, not project history. Review it like other process docs. The STEP index,
phase folders, archived PLANs, and archived substep prompts remain protected project state.

### Legacy local user profile fields

Older Throughstone projects stored the first user's communication preferences in
`overview.md` under **Your experience level** and **Planning communication style**. Newer
projects store those personal preferences in root `.throughstone/local-user.md`, because each
contributor has their own local profile.

When reviewing or applying this migration, compare the related files as a coherent group. It is
not just a `METHOD.md` change:

- `BOOTSTRAP-PROMPT.md` defines the two local-profile questions and file shape.
- `AGENTS.md`, `METHOD.md`, and `ONBOARDING.md` define when agents and additional contributors
  create or read the local profile.
- `scripts/check.sh` reports legacy `overview.md` preference sections.
- `templates/overview-template.md`, `templates/planning-session.md`,
  `templates/step-plan-template.md`, `templates/substep-prompt-template.md`, and
  `templates/architecture-sessions/*.md` keep future sessions from reading project-level
  preference fields.
- `prompts/README.md` carries the STEP-planning communication-style behavior.
- `runbooks/collaboration.md` explains the multi-contributor local-profile expectation.

During an update, treat those old `overview.md` sections as legacy project-state drift:

1. Create or update root `.throughstone/local-user.md` for the active user, optionally using
   the old `overview.md` values as a starting point if they actually describe that user.
2. Remove the old personal-preference sections from `overview.md` only after confirming they
   are not project facts.
3. Do **not** migrate them automatically in updater tooling or `doctor`: in a team, the old
   values may describe the original maintainer, not the active contributor.

`scripts/check.sh` warns when it sees these legacy sections. The warning is advisory and does
not fail the check.

### 1.7 migration

**Upgrading from 1.6? Start here.** This release rewrites no project files. Only two defaults
shift, and only once you pull the new tooling/templates: the doc-maturity ladder and the check-in
cadence. Fast path:

1. Pull the process docs + tooling as one review-required group (`METHOD.md`,
   `runbooks/check-in.md`, `templates/planning-session.md`, `scripts/status.sh`, `scripts/check.sh`).
2. Want the old check-in window (DUE 10 / OVERDUE 20)? Add `<!-- CHECK-IN-CADENCE: 15 -->` to
   `overview.md`; otherwise omit it to take the new default of 20 (DUE 15 / OVERDUE 25).
3. Optionally reinterpret old `Status: MVP` / `Status: Stable` architecture docs as
   `Status: Current` (no forced change; `check.sh` keeps passing either way).
4. Create `inputs/` and copy its `README.md` if you want the bring-your-own-docs drop point.
5. Everything else is future-only or purely behavioral — the per-area detail below covers each.

The **1.7 base refactors** generalize the method — flexible Phase-1 naming, decoupled
doc metadata, a deferred-coverage check-in sweep, a recorded release stage, and existence-aware
repo scaffolding — so it also fits later phases, re-runs, custom conventions, and existing
codebases. Overall this is **low-friction: nothing is auto-rewritten**, and the §2 file-bucket
rules apply unchanged.
There are **two opt-outable default shifts** (the doc-maturity ladder and the check-in cadence);
apply each area as a coherent review-required group, as with the legacy migration above.

**Doc metadata & maturity ladder.**

- *Templates for future use* (`templates/architecture-doc-template.md`): new architecture docs get
  the `Draft → Current → Deprecated` comment and the optional `Coverage:` field; existing generated
  docs are not rewritten.
- *Process docs* (`METHOD.md` §6, `runbooks/check-in.md`): adopt the new Version / Status / Coverage
  semantics and the "check-in skips `Status: Deprecated`" rule.
- *Project state* (existing `architecture/*.md`): never auto-updated. A doc still carrying
  `Status: MVP` or `Status: Stable` keeps passing `check.sh` (it validates the field's presence,
  not its value), but those rungs are retired. Recommended one-time, manual reinterpretation:
  `Status: MVP → Current`, `Status: Stable → Current`. Adopt `Deprecated` / `Coverage` where useful.
  No forced change.

**Deferred-coverage check-in sweep.**

- *Process docs* (`runbooks/check-in.md`): the periodic check-in gains a deferred-coverage sweep. It
  reads the `Coverage:` field above, so it only acts on docs marked `Coverage: deferred`; a project
  that never defers coverage sees no change. No `status.sh` change.
- *Project state* (existing `architecture/*.md`): never auto-updated. If a doc carries
  `Coverage: deferred`, the next check-in surfaces it with a disposition (backfill / still defer /
  seed a `Planned` STEP + `risks.yml` risk); a `Status: Deprecated` deferred doc is listed as
  retired, never backfilled.

**Flexible Phase-1 naming.**

- *Templates for future use* (`templates/step-index-seed.md`, `templates/step-plan-template.md`,
  `templates/phase-readme-template.md`, `templates/architecture-sessions/02-phasing-roadmap.md`,
  `BOOTSTRAP-PROMPT.md`): new projects get the `{{PHASE_1_NAME}}` heading placeholder, the kickoff
  milestone-kind question, and the milestone-general wording; existing generated files are not
  rewritten.
- *Process docs* (`METHOD.md` §1, `templates/architecture-sessions/14-cross-cutting-review.md`,
  `runbooks/collaboration.md`, `prompts/README.md`): adopt the create-at-archive convention — the
  Phase-1 folder is created from the `## Phase 1 — <name>` heading when STEP-1 is archived, not
  shipped pre-named — and the reworded "Phase-1 shortcut" foreclosure phrase (also in
  `templates/architecture-sessions/05-scaling-performance.md`).
- *Project state* (an existing project's `prompts/001-mvp/` folder and its `## Phase 1 — MVP`
  heading): never auto-updated. A project already on `001-mvp/` keeps it — the archive folder that
  exists is the one STEP-1 landed in, and nothing renames it. New phases (Phase 2+) already create
  their own folders. No forced change; `status.sh` / `check.sh` are unaffected (they key on index
  rows, not folder names).

**Release stage as a recorded fact.**

- *Templates for future use* (`templates/overview-template.md`, `BOOTSTRAP-PROMPT.md`): new projects
  get the optional **Release stage / launch target** line and a Stage-1 kickoff question (leading
  with a pre-launch default); existing generated `overview.md` files are not rewritten.
- *Process docs* (`METHOD.md` §4, `templates/architecture-sessions/03`, `04`, `05`, `06`, `07`, `08`,
  `09`, `10`, `conditional-identity-auth.md`, `conditional-privacy-compliance.md`,
  `registries/risks.yml`): sessions now calibrate their *breadth* defaults (how big / how public) to
  the recorded release stage + load, and their *rigor* (security, privacy, availability) to blast
  radius / data sensitivity — replacing the old "for an MVP" shorthand. The decisions reached and
  docs produced are unchanged; only the framing moves off an assumed "MVP."
- *Project state* (an existing project's `overview.md`): never auto-updated. Add the optional Release
  stage line if it's useful — nothing requires it, and `check.sh` never reads it. The release stage
  stays independent of the Phase-1 scope name and of doc `Status`; the three axes don't collide.

**Existence-aware repo scaffolding.**

- *Process docs* (`templates/planning-session.md`): the implementation planning session's
  repo-scaffolding work-item now scaffolds a repo only if it isn't already registered in
  `registries/repos.yml` with a filled-in README; an already-registered repo is left in place, not
  re-created. Adopt the reworded work-item. No `status.sh` / `check.sh` change.
- *Project state* (existing `registries/repos.yml` and existing repos): never auto-updated. Nothing is
  rewritten. The change is behavioral — a planning re-run (or a planning pass over a project that
  already has these repos) no longer proposes re-scaffolding a repo that's already registered; a first
  run with no code-repo rows scaffolds everything exactly as before.

**Milestone-relative planning STEP-shape.**

- *Process docs* (`templates/planning-session.md`): the implementation planning session's STEP
  sequence (work-item 2, plus work-item 1's "first STEP is scaffold" line) is now milestone-relative —
  build or extend what the milestone needs, in dependency order, given what already exists, with the
  scaffold → data → capabilities → integration shape kept as the worked example for a first run. Adopt
  the reworded work-items. No `status.sh` / `check.sh` change.
- *Project state* (an existing project's roadmap in `prompts/STEP-index.md`): never auto-updated.
  Nothing is rewritten. The change is behavioral — a planning re-run or a later-phase plan now reads as
  *extend what's built* rather than *rebuild from scratch*; a first run with nothing built produces the
  same scaffold-first outline as before.

**Target the first uncompleted phase in planning.**

- *Process docs* (`templates/planning-session.md`): the implementation planning session now targets
  **the first uncompleted phase** — the lowest-numbered roadmap phase whose STEPs aren't all complete —
  instead of hardcoding **Phase 1** throughout; it defaults to Phase 1 on the first run. Adopt the
  reworded references (nine "Phase 1" mentions → "the target phase") and the new bullet deriving the
  phase from the roadmap. No `status.sh` / `check.sh` change.
- *Project state* (an existing project's roadmap in `prompts/STEP-index.md`): never auto-updated.
  Nothing is rewritten. The change is behavioral — once Phase 1 is complete, a planning re-run reads the
  next phase's scope and outlines its STEPs instead of being pointed back at Phase 1; a first run still
  targets Phase 1 with the same outline as before.

**Project-selectable check-in cadence.**

- *Templates for future use* (`templates/overview-template.md`): new projects get the optional,
  documented `<!-- CHECK-IN-CADENCE: 20 -->` marker beside `PROJECT-STATUS`; existing generated
  `overview.md` files are not rewritten.
- *Process docs / tooling* (`scripts/status.sh`, `scripts/check.sh`, `METHOD.md` §5 + §10.7,
  `AGENTS.md`, `templates/planning-session.md`, `runbooks/check-in.md`, `runbooks/README.md`,
  `runbooks/secrets-rotation.md`, `runbooks/dependency-supply-chain.md`, `prompts/README.md`): the
  check-in rhythm is reframed as "about every 20 STEPs (the project's cadence, adjustable)", and the
  updated `status.sh` reads a `CHECK-IN-CADENCE` marker from `overview.md` (default 20), flagging a
  heads-up (DUE) at `N-5` and OVERDUE at `N+5`. **This is a deliberate, opt-outable default shift:**
  once you pull the new `status.sh`, its check-in nagging recenters from today's DUE 10 / OVERDUE 20 to
  **DUE 15 / OVERDUE 25**. `check.sh` gains an optional warning (never a failure) if the marker is
  present but not a positive integer.
- *Project state* (an existing project's `overview.md`): never auto-updated, and no line is required.
  To keep the **exact previous window** (DUE 10 / OVERDUE 20), add `<!-- CHECK-IN-CADENCE: 15 -->`; for
  any other rhythm use that number (e.g. `50` → DUE 45 / OVERDUE 55); omit the line to take the new
  default of 20. The cadence stays a judgment-based guideline — you still place each check-in at a
  sensible breakpoint.

**Workspace model accepts in-place repos.**

- *Process docs* (`METHOD.md` §7, `registries/repos.yml` header): newly documented convention — a repo
  may be registered by a `location:` **outside the `Code/*` shell** (an absolute or otherwise arbitrary
  path), referenced in place, in addition to the created-as-sibling default. `scripts/setup-workspace.sh`
  already honors `location:` verbatim (clones from `remote:` into it, or references the repo in place
  when there's no remote), so there is **no tooling change** to pull. Keep `location:` and `remote:`
  distinct — a clone URL belongs in `remote:`, never folded into `location:`.
- *Project state* (existing `registries/repos.yml` and existing repos): never auto-updated. Nothing
  changes and no line is required — the `Code/*` sibling layout stays the default and existing rows are
  kept exactly as they are. Point a `location:` outside `Code/*` only if you want a repo referenced
  where it already lives. No `status.sh` / `check.sh` change.

**Bring-your-own inputs (`inputs/` folder).**

- *New scaffold folder* (`Code/{{PROJECT}}-docs/inputs/` + its `README.md`): a durable drop point
  for documents you already have (product specs, prior architecture/protocol docs, UI designs,
  research). To adopt in an existing project, create the folder and copy `inputs/README.md` from
  the newer scaffold; `init.sh` seeds it for new projects.
- *Process docs* (`METHOD.md` §4, `AGENTS.md`, `BOOTSTRAP-PROMPT.md`, `README.md`,
  `templates/overview-template.md`, all `templates/architecture-sessions/*`,
  `templates/planning-session.md`, `templates/substep-prompt-template.md`): sessions now read
  relevant `inputs/` documents alongside `overview.md`; the kickoff tells the user up front they
  can bring documents; a doc provided in chat is saved into `inputs/`. Adopt the reworded
  read-lists and the kickoff note. No `status.sh` / `check.sh` change.
- *Project state* (your `inputs/` contents): entirely yours — nothing is auto-created or
  rewritten. The folder is optional; a session reads what's there and ignores an empty folder.

### 1.8 migration

**Templates, guidance text, and several refusals that did not exist before — nothing you already
produced is rewritten.** Edits to `templates/architecture-sessions/*.md`, `METHOD.md` §7 and the
files that carry its rules, all *Templates for future use* under §2, so they affect work you do
after pulling them.

What is worth knowing before you pull: `init.sh` and `scripts/apply-project-license.sh` both refuse
in cases where they previously proceeded. Those refusals are the point of the release — each one
stood between the method and a write into a repository it did not create — but a script of yours
that relied on either running unattended may now stop and ask. Each item below says what changed
and what to check.

- **`init.sh --registries=no` is deprecated and now does nothing.** It pruned `registries/` in
  mono-repo layout, on the argument that a self-contained root repo has no sibling repos to
  inventory. That argument is about `repos.yml`; the directory also holds `risks.yml`, the
  accepted risk / tech-debt register §7 requires, and `security-reviews.yml`, which the
  security-review runbooks and their report templates read. Pruning removed all three and left
  the generated project's own docs citing files it did not have — and because those citations are
  prose rather than Markdown links, `scripts/links.sh` and `scripts/check.sh` both reported the
  project clean. The flag is still accepted so existing scripts keep working, prints one
  deprecation line, and is removed in a later release. **One thing to check:** if you generated a project
  with `--registries=no`, it is missing all three registries. Copy `registries/` from a freshly
  generated project (or from the template) into your docs hub — the two seed rows in `repos.yml`
  describe the docs hub and `prompts/`, and the other two files start empty.

- **`registries/repos.yml` rows carry a `readme:` field.** It records what the method did to that
  repo's README — `stamped` for a repo the method created, `augmented` where a `Role in <project>`
  section was added to an existing README, `written` where the method wrote a README for a repo
  that had none, `role-stated` where the README already said what the repo is within the system,
  `declined` where the owners said no, and `not-proposed` while the addition is still to be put to
  them. The registry's own header defines each. It exists because `METHOD.md` §7 lets a decline
  stand for every remaining repo, and told you to record that without naming anywhere to record it
  — so the periodic check-in, which skips a declined repo, had no way to tell one from a repo
  nobody had asked. **One thing to check:** your existing rows have no value, which reads as *not
  recorded* rather than defaulting to anything. Nothing rewrites them. Fill them in at your next
  check-in — the repos the method created are `stamped`, and only you know what happened to the
  rest.

- **`registries/repos.yml` rows also carry a `license:` field.** It records what each repo is
  licensed under: the bootstrap posture for a repo the method created, and whatever the repo
  already says — an identifier and the file it came from, or `none stated` — for one registered in
  place. §7 already told you to record an in-place repo's licensing "in the repo inventory entry",
  and no field there held it. It exists because a project whose repos don't share one license has
  nowhere else to show that, and it is a record rather than an instruction: the repo's own license
  file stays authoritative and this line is a copy that can drift. **One thing to check:** your
  existing rows have no value, which reads as *not recorded* rather than "same as everything
  else". Nothing rewrites them — `repos.yml` is project state. The two seed rows a fresh bootstrap
  writes take the posture from `.throughstone/project-license`; backfill the rest by hand whenever
  you want the licensing picture in one place.

- **The go-ahead is now conditional.** Each session file's closing paragraph opens "If you were sent
  here to run this session…" and ends by releasing a reader who wasn't sent to run it. When you
  invoke a session normally, behavior is unchanged — you type `Run STEP-1.N` and get the first
  question back exactly as before. What changes is a file *read* for another purpose (the
  Cross-Cutting Review checking conditional applicability, the check-in re-evaluating them): those
  readers are now told the go-ahead isn't theirs, instead of relying on their own instructions to
  outweigh it.
- **One work-list heading.** The Glossary and Cross-Cutting Review templates now head their work list
  `## Decisions to make (in order)`, matching the other fifteen, each with a note explaining what its
  items are. If you have **customized session templates or added your own**, adopt the same heading so
  generic readers find your work list too — `METHOD.md` §4 documents the skeleton, and it is the only
  change you might want to make by hand.
- **Lifting a document into `architecture/` now names all three header fields.** `inputs/README.md`
  told you to add the `Version` / `Status` header and omitted the **Version Log**, which `check.sh`
  check 4 also requires of every numbered architecture doc — so a lifted spec could fail the check
  that guards it. Pull the updated `inputs/README.md`. If you have **already lifted** a document,
  run `scripts/check.sh`: check 4 names any doc missing a field.
- **The STEP index's status legend now mentions `N/A`.** A substep whose area structurally doesn't
  apply is marked `N/A`, which `check.sh` and the next-action resolver have always accepted, but the
  legend at the top of `prompts/STEP-index.md` listed only the five STEP states. Optional: copy the
  added line into your project's index if you want the legend to describe what the file may contain.
- **A `Coverage:` line is now a sentence, not a bare word.** `METHOD.md` §6 and
  `templates/architecture-doc-template.md` both showed the optional `Coverage:` field as a lone
  token (`deferred`), which tells a reader arriving months later nothing about whether the gap
  blocks them — and gives the check-in that resurfaces it nothing to weigh. Both now ask for what is
  missing, how big it is, and what it means for someone building on the doc, written as an ordinary
  bold header field (`**Coverage:** deferred — …`). **One thing to check:**
  if any of your architecture docs already carries a bare `Coverage:` value, expand it the next time
  that doc is touched; nothing rewrites it for you.
- **The deferred-coverage sweep now reads the field instead of matching a phrase.**
  `runbooks/check-in.md` told the sweep to enumerate docs "carrying `Coverage: deferred`", a literal
  string that a doc written from the template never contains — the field is bold, like every other
  header field. It now takes any `Coverage:` field whose value isn't `full`. Pull
  `runbooks/check-in.md` with the two files above; if a past check-in reported no deferred coverage,
  it is worth re-running the sweep once by hand.
- **A repo's remote changes only when you ask, and the in-place rules read straight.** Three
  wording fixes in §7, no behavior change. *Remotes:* the rule said "do not create a remote for a
  repo that has one", implying you could create one for a repo that has none, and said nothing
  about removing one — it now names all three verbs (never created, repointed, or removed as a
  side effect) and covers every repo the same way, matching what `init.sh` already does (no
  remotes unless asked). *The gate:* "every write above is proposed" sat over five bullets of
  which only two are writes, so it now names them — the README addition and the Throughstone
  notice that follows it — says the other three are things the method doesn't do, and says that
  only the README addition is put to the repo's owners, the notice following automatically from an
  addition they already accepted. *The fallback:* its case list was README- and licensing-only and
  read as exhaustive; it is now explicitly illustrative and includes a visibility and a remote
  example. Pull `METHOD.md` §7 with `templates/planning-session.md` and
  `templates/repo-readme-template.md`. **One thing to check:** nothing.
- **An accepted change to a repo you already had is committed on a branch and left there.** §7 said
  to propose the `Role in <project>` section and wait for a yes, and then said nothing about what
  happens after the file changes on disk — no branch, no commit, no push. The obvious continuation
  was to commit onto whatever branch was checked out, which on a running system is usually `main`,
  and push it to their remote. A yes settles what the text should say; it says nothing about how
  that change should reach a trunk, and every team has its own answer. So the method now makes a
  branch, commits **only the file(s) proposed** (never `git add -A`, which would sweep up work in
  progress), tells you the branch and commit, and stops — no push, no pull request, no merge. If
  the working tree already has uncommitted changes to that file, it stops and says so instead.
  Pull `METHOD.md` §7 with `templates/planning-session.md` and `templates/repo-readme-template.md`.
  **One thing to check:** if an earlier run committed such a change onto a shared branch or pushed
  it, that commit is still there and is worth reviewing like any other.
- **An `ARCHITECTURE.md` is never added to a repo you already had.** §7 said "a repo with real
  internal complexity adds an `ARCHITECTURE.md` at its root" in its general repo paragraph, without
  scoping it — and the comment suggesting one lives in the repo README template's Overview section,
  which is exactly what gets written for an in-place repo that has no README. Adopted repos are
  also exactly the ones with real internal complexity. It is now scoped to repos the method
  creates; an in-place repo's internal design is written up in the docs hub's `architecture/`
  instead. **One thing to check:** nothing, unless a run added such a file to a repo of yours.
- **Nothing is made public without you saying so, and an in-place repo's remote is left alone.**
  §7 listed what happens to a repo the method did not create — its README, its CI, its licensing,
  the Throughstone notice — and said nothing about its remote or its visibility. The general
  "a repo registered in place is not scaffolded at all" was meant to cover them, but a general
  statement followed by a list reads as covering the list, which is the same gap that once let the
  license helper assume every repo was one the method had scaffolded. Two rules now say it
  outright. **Remote and visibility are the repo's owners':** create no remote for a repo that has
  one, repoint no existing one, change no visibility; record the URL it already has in its
  `remote:` field and leave the repo alone. **And nothing is made public without an explicit
  go-ahead** — for any repo, including ones the method creates. Public is never inferred from an
  open-source license, a public sibling, or a project describing itself as open source; with no
  answer given the answer is private. `init.sh` already defaulted that way, so no tooling changes;
  what changes is that the rule is stated where an agent reads it. Pull `METHOD.md` §7 with
  `templates/planning-session.md` and `templates/repo-readme-template.md`. **One thing to check:**
  if a repo you registered in place had its visibility changed while adopting it, that is worth
  looking at now — publishing cannot be undone, and a repo made public stays retrievable.
- **A decline can be standing, so you are not asked once per repo.** Every write into a repo
  registered in place is proposed first, which is right — but the *question* behind each proposal
  is the same one every time, so a project with several such repos put it to the same owners repo
  after repo, and someone who had already said no got asked again for each remaining one. Nothing
  about the gate changes: the text is still shown and still waits for an answer, because the text
  differs per repo. What is added is that a decline now establishes whether it covers this repo or
  the rest, and a standing one stops the proposals and records that those repos document
  themselves. It runs one way only — a yes is never carried forward, since the next repo's text is
  its own proposal. Pull `METHOD.md` §7 with `templates/repo-readme-template.md`. **One thing to
  check:** nothing; this only removes repeat asking.
- **Licensing is no longer its own rule.** `METHOD.md` §7 had grown a separate doctrine paragraph
  for licensing — "the method records licensing; it never establishes licensing for code it did not
  create" — sitting alongside separate rules for the README, for CI, and for the Throughstone
  notice. They were always the same rule applied to four artifacts: **a repo the method did not
  create keeps what it already has.** §7 now states that once, with each of them as a consequence
  under it and one gate covering all of them (propose the exact text, wait for an answer). **No behavior
  changes** — every individual rule says what it said, and the helpers are untouched. What changes
  is that the rationale lives in one place instead of being re-derived in each, and the files that
  cite it — `AGENTS.md`, the planning session, and the repo README template — now quote the general
  rule rather than a licensing-specific one. Pull those three with `METHOD.md`. **One thing to
  check:** nothing; if you have local edits quoting the old licensing sentence, they are still
  true, just narrower than the rule they came from.
- **The project license is applied only to repos the method creates.** `METHOD.md` §7 already let a
  repo be **registered in place** — referenced where it sits, rather than created under `Code/` —
  but every instruction around `scripts/apply-project-license.sh` was written as though every repo
  were one the method had just scaffolded. Pointed at a repo that existed beforehand, the helper
  would give it the project's `LICENSE` and a `LICENSING.md` asserting that license over the whole
  repository. It now **refuses** a target that already states its own terms (`COPYING`, `NOTICE`,
  `LICENSE.md`, `LICENSE-<id>`, …) before writing anything, and `METHOD.md` §7, `AGENTS.md`, the
  planning session, and the repo README template state the rule: **the method records licensing; it
  never establishes licensing for code it did not create.** No effect on repos you scaffolded
  through the method — they carry none of those files, and re-running the helper on one behaves
  exactly as before. **One thing to check:** if you have registered an existing repo in place and
  ran the helper on it, look at that repo's `LICENSE` / `LICENSING.md` and decide, as its owner,
  whether they say what you intend.
- **`.throughstone/project-license` is described more narrowly.** The posture file was called "the
  project license" everywhere, but it only ever governed **Throughstone-authored and method-created
  material** — your docs hub, `prompts/`, and any repo the method creates. Nothing about the file
  changes; the wording around it does, in `METHOD.md` §7, `AGENTS.md`, `README.md`, the planning
  session, and the helper's header. Pull them with the group below. **One thing to check:** if a
  repo of yours was registered in place rather than created by the method, its licensing is its
  own — record what it actually uses beside its inventory entry rather than assuming the posture.
- **A repo you registered in place is augmented, not stamped.** `templates/repo-readme-template.md`
  told you to stamp a copy into each repo "as it's created", which is the only case it considered —
  so pointed at a repo that already existed, the instruction reads as "overwrite its README". That
  repo's README is usually its most-read file. It now gets a short `Role in <project>` section
  added instead, proposed before anything is written, with every existing section left alone. The
  rule keys on whether a README is already there, not on how the repo got here: where a registered
  repo has none, its README is written from the full template — that one file, with nothing else
  about the repo scaffolded. No change for repos you scaffold through the
  method: those are still stamped from the full template.
  **One thing to check:** if you registered an existing repo in place and its README was replaced
  with the template, its previous content is in that repo's git history.
- **The CI gate is never installed into a repo you registered in place, and the Throughstone
  notice has its own mode.** `templates/ci/code-repo-ci.yml` fails until configured — right for a
  new repo, wrong for one that already has CI, where it would replace or duplicate the workflow
  that gates your merges. It is now for created repos only; record what an in-place repo runs in
  the Test Strategy doc instead. Separately, where the method leaves Throughstone-authored
  material in such a repo (the `Role in <project>` README section), place its notice with
  `scripts/apply-project-license.sh --notice-only <repo>` — it writes `LICENSE-THROUGHSTONE` plus a
  `LICENSING.md` that disclaims the rest of the repository, and never a project `LICENSE`. **One
  thing to check:** if you registered a repo in place and dropped the CI template into it, decide
  with its owners whether that workflow should stay.

Pull `templates/architecture-sessions/*.md`, `METHOD.md` §4, §6 and §7, `AGENTS.md`, `README.md`,
`inputs/README.md`, `templates/architecture-doc-template.md`, `templates/planning-session.md`,
`templates/repo-readme-template.md`, `runbooks/check-in.md`, and
`scripts/apply-project-license.sh` as a group. Nothing else is affected: no `status.sh` /
`check.sh` change, no project state touched.

### 1.7.1 migration

**Upgrading from 1.7.0?** A small follow-up that gives the `inputs/` folder a lifecycle. It rewrites
no project files and is greenfield-inert — the new ledger simply starts empty. Fast path:

1. Pull the process docs as one review-required group (`AGENTS.md`, `METHOD.md` §4,
   `runbooks/check-in.md`, `templates/architecture-sessions/01-system-overview.md` and
   `03-architecture-overview.md`, `templates/substep-prompt-template.md`,
   `templates/planning-session.md`, `templates/reports/check-in-report-template.md`).
2. Add the ledger: copy the scaffold's empty `inputs/inputs-index.md` (and the updated
   `inputs/README.md` guidance with it), then list any inputs you already have as `Live`.
3. Nothing else now. `inputs/archive/` is created only when you first retire an input, and the next
   check-in's inputs sweep is what surfaces a superseded input for a retire/keep decision.

The change establishes that **inputs are point-in-time** and `architecture/` is the living truth:
where a generated `architecture/` / `adr/` doc covers the same ground as an input, the generated doc
wins, and architecture-grade inputs are lifted into `architecture/` (a spec often a whole-file copy
or a light reformat). This is **low-friction: nothing is auto-rewritten**, and the §2 file-bucket
rules apply unchanged.

**Inputs lifecycle.**

- *New project-state file* (`inputs/inputs-index.md`): copy the scaffold's empty ledger in; from
  then on it is yours to maintain, like a registry (`registries/*.yml`). Record each existing input
  as `Live`, and mark parts `Superseded` as an `architecture/` doc captures them. A fresh project
  ships it empty, so a first run reads all of `inputs/` exactly as before.
- *Process docs* (`AGENTS.md` ground rules, `METHOD.md` §4, `runbooks/check-in.md`, the
  system-overview / architecture-overview session templates, `templates/substep-prompt-template.md`,
  `templates/planning-session.md`, `templates/reports/check-in-report-template.md`): adopt the
  point-in-time authority rule, the `inputs/archive/` read-exclusion, and the check-in inputs sweep.
  Apply them as a coherent review-required group. No `status.sh` / `check.sh` change.
- *Project state* (your `inputs/` contents): never auto-updated. Your existing input files are not
  touched or moved; they simply start `Live` in the ledger, and any retirement to `inputs/archive/`
  happens only when you decide it at a check-in.

## 3. Manual Mode

This guide works today even without updater tooling, a project manifest, or an upstream update
catalog.

1. Pick the target Throughstone release or commit from
   `https://github.com/mherschberg/Throughstone`.
2. Read the target release notes / `CHANGELOG.md` and identify the scaffold/process changes
   you may want.
3. Compare only scaffold/process material: `METHOD.md`, `AGENTS.md`,
   `UPDATING-THROUGHSTONE.md`, `prompts/README.md`, `templates/`, `runbooks/`,
   `coding-standards/`, and `scripts/`.
4. Treat the file buckets in §2 as the authority. Never manually copy protected project state
   from upstream.
5. For each candidate change, write a short report: target release/ref, files reviewed,
   implication/risk, recommendation, and whether it needs a tracked STEP.
6. Apply only the reviewed changes the user explicitly approves, following the apply and STEP
   rules in §8 and §10, then run `scripts/check.sh`.

Manual mode is slower than tooling, but it is the default path until the manifest and catalog
described below exist.

## 4. Future Tooling Artifacts

A future updater should read two kinds of metadata.

### Project Manifest

The manifest lives in the docs hub at `Code/{{PROJECT}}-docs/.throughstone/manifest.yml`
when viewed from the workspace root. Within the docs hub, that same path is
`.throughstone/manifest.yml`.

The default upstream source is `https://github.com/mherschberg/Throughstone`. If a project
intentionally tracks a fork or private mirror instead, record that source in the manifest so
future checks compare against the right upstream.

```yaml
# .throughstone/manifest.yml
throughstone:
  installed_version: "0.1.0"
  installed_ref: "abc1234"
  source: "https://github.com/mherschberg/Throughstone"

files:
  - local_path: "METHOD.md"
    upstream_area: "docs-hub"
    upstream_path: "METHOD.md"
    kind: "process"
    policy: "review"
    installed_sha256: "..."

  - local_path: "scripts/status.sh"
    upstream_area: "docs-hub"
    upstream_path: "scripts/status.sh"
    kind: "script"
    policy: "review"
    installed_sha256: "..."

  - local_path: "templates/substep-prompt-template.md"
    upstream_area: "docs-hub"
    upstream_path: "templates/substep-prompt-template.md"
    kind: "template"
    policy: "future-only"
    installed_sha256: "..."
```

Manifest field meanings:

- `local_path` is relative to the initialized docs hub. For example,
  `Code/acme-docs/scripts/status.sh` on disk is recorded as `scripts/status.sh`.
- `upstream_area` names the logical scaffold area in the Throughstone source. For now, this
  guide only defines `docs-hub`, which maps to upstream `Code/{{PROJECT}}-docs/`.
- `upstream_path` is relative to `upstream_area`. For example, `upstream_area: "docs-hub"` plus
  `upstream_path: "scripts/status.sh"` maps to upstream
  `Code/{{PROJECT}}-docs/scripts/status.sh`.
- Future tooling combines `source`, `installed_ref`, `upstream_area`, and `upstream_path` to
  find the upstream file, and combines the initialized docs hub path with `local_path` to find
  the local file.

Keep upstream identifiers placeholder-free. Do not store the initialized project slug in an
upstream path, and do not depend on the Throughstone project-placeholder token surviving
bootstrap; `init.sh` intentionally replaces it in file contents.

The manifest is advisory state, not magic truth. If it is missing, stale, or inconsistent,
the updater must say so and fall back to a manual comparison.

### Upstream Update Catalog

Once updater tooling exists, each Throughstone release should ship an update catalog:

```yaml
version: "0.2.0"
changes:
  - area: "docs-hub"
    path: "scripts/setup-workspace.sh"
    group: "workspace-setup"
    kind: "script"
    risk: "medium"
    summary: "Improves repo registry parsing when only some repos have remotes."
    implications:
      - "Changes clone behavior for multi-repo workspaces."
      - "Does not modify project docs or application code."
    recommendation: "Review, then apply if setup-workspace.sh was not customized."

  - area: "docs-hub"
    path: "templates/planning-session.md"
    group: "planning-flow"
    kind: "template"
    risk: "low"
    summary: "Adds stronger CI scaffolding guidance."
    implications:
      - "Affects future planning sessions only."
      - "Does not update existing STEP plans."
    recommendation: "Update for future use."
```

Catalog entries must name implications plainly. The updater should also compute mechanical
risk signals instead of relying only on maintainer-written summaries.

## 5. Compare Model

For every scaffold-managed file, compare three versions:

| Version | Meaning |
|---------|---------|
| **base** | the file content recorded at install time, identified by `installed_sha256` |
| **local** | the file currently in this project |
| **upstream** | the file in the target Throughstone release |

Classify the result:

| Classification | Meaning | Default action |
|----------------|---------|----------------|
| **already-current** | `local == upstream` | Report only. |
| **upstream-only** | `local == base`, upstream changed | Candidate for apply, still review risk. |
| **local-only** | local changed, upstream unchanged | Keep local; no update needed. |
| **diverged** | local changed and upstream changed | Manual review or merge; do not auto-apply. |
| **baseline-unknown** | install-time baseline is missing or cannot be verified | Report only; require manual review before any baseline is adopted or update is applied. |
| **untracked** | file is not in the manifest | Report only unless explicitly added to manifest. |
| **protected** | file is project-owned or generated | Never auto-apply. |
| **manifest-invalid** | checksum/path/ref is missing or inconsistent | Stop automatic actions; require manual comparison. |

Use precise wording: **"unchanged locally"** is acceptable; **"safe to apply"** is not.
For projects without a trustworthy install-time manifest, do not backfill the manifest by
treating today's local files as the original base. Mark those files `baseline-unknown` unless
their local content can be verified against a known installed upstream ref after bootstrap
normalization, or unless the user explicitly adopts a reviewed file as the new managed
baseline.

## 6. Mechanical Risk Signals

The updater should flag at least these signals:

- executable bit changed
- shell script changed
- file contains or changes `git`, `gh`, `ssh`, `curl`, `wget`, `rm`, `mv`, `cp`, `chmod`,
  `chown`, `sudo`, `aws`, `kubectl`, or remote URLs
- status resolver or agent context changed (`status.sh`, `AGENTS.md`, `METHOD.md`)
- collaboration or numbering rules changed
- CI workflow changed
- file deletion or rename
- placeholder handling changed (the Throughstone project-placeholder token, generated project
  slug, repo paths)
- update group is incomplete
- affected repo has uncommitted changes

Mechanical signals do not replace the catalog; they catch omissions and force review.

## 7. Future Tooling Check Flow

1. Confirm the docs hub and workspace layout.
2. Read `Code/{{PROJECT}}-docs/.throughstone/manifest.yml` (or
   `.throughstone/manifest.yml` from inside the docs hub). If absent, use manual mode (§3)
   instead.
3. Fetch or locate the target Throughstone release metadata. If the process executes
   downloaded updater code, pin the release/ref and verify it using the release's published
   provenance mechanism before execution.
4. Read the upstream update catalog.
5. Build the three-way comparison for every manifest file.
6. Group related changes. If a group is incomplete, mark the whole group review-required.
7. Print a report with:
   - classification
   - bucket/policy
   - risk level and mechanical risk signals
   - human implications from the catalog
   - whether the update is future-only, review-required, manual-merge, or protected
8. Stop. The default tooling command must not write files.

## 8. Apply Rules

Only apply when all of these are true:

- user explicitly requested apply
- every affected repo has a clean working tree and index before the updater creates or switches
  branches and before it writes files
- upstream release/ref was selected; any downloaded executable updater code was verified using
  the release's published provenance mechanism
- file is not protected
- file is either `upstream-only` with a verified baseline or the user selected a manual merge
  result
- all files in the required update group are included

Branch rule:

- If the update meets the STEP threshold in §10, reserve a STEP and use the normal
  `step-NNNN-short-name` branch.
- If the update does not meet that threshold, use a dedicated scaffold-update branch so the
  change is still reviewable and easy to roll back.

This guide describes the process whether it is done manually or by future updater tooling.
Throughstone does **not** currently ship a `throughstone-update.sh` script. If/when one is
added, use command names that make the risk model clear, for example:

```bash
./throughstone-update.sh check
./throughstone-update.sh diff
./throughstone-update.sh apply --unchanged-local-only
./throughstone-update.sh apply METHOD.md scripts/status.sh
```

Avoid names like `--safe` or `--clean-only`; they imply more certainty than the updater has.

After apply:

1. Recompute and write manifest checksums for updated scaffold files.
2. Run the docs hub checks (`scripts/check.sh`).
3. Preserve the update report in the branch or commit message.
4. Tell the user what changed, what was skipped, and which manual review items remain.

## 9. Future Root Updater Shape

A future root updater may be tiny and replaceable:

1. locate the docs hub
2. read the manifest path
3. pin the requested upstream release/ref and verify executable updater code using the
   release's published provenance mechanism
4. run the verified updater from a temporary location
5. pass only project root, docs hub path, manifest path, and requested command

It must not store project state outside the manifest. If the root updater itself changes,
that update is reported and applied like any other script update.

## 10. When To Make It A STEP

Make a tracked STEP when the update:

- changes `METHOD.md`, `AGENTS.md`, `status.sh`, collaboration rules, or STEP/ADR numbering
- touches more than one repo
- changes CI behavior
- requires manual merge decisions
- changes how future architecture sessions or planning sessions behave
- would affect an active team

The STEP's PLAN can be thin: point to this guide, list the update groups under review, and
define done as "report reviewed, selected updates applied, checks passed, manifest refreshed,
and skipped/protected files recorded."
