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
| **Stamped/generated files** | a repo `README.md` Throughstone stamped, the `## Role in <project>` section it adds to a README the repo already had, `LICENSE-THROUGHSTONE`, copied CI workflows, `.env.example`, STEP plans | Project-owned after creation. Never auto-update; provide advisory diffs only if explicitly requested. |
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

### 1.8 migration

**Upgrading from 1.7? Nothing of yours is rewritten. There is one small edit worth making** —
two lines per row in `registries/repos.yml`, which the project doctor now asks for by name —
**one shape to look at in that same file**, since every value there has to sit on one line —
**and, if your project is mono-repo-for-now, one thing to check**: whether your CI gate has ever
actually run. Beyond those, nothing is required of
you unless you are about to split a repository. The release adds a runbook for that, repeals one
rule, and starts recording which of your repos Throughstone may write into — and now says what that
recording means, in `METHOD.md` §7 and a second new runbook. Fast path:

1. Pull the process docs as one review-required group (the new `runbooks/splitting-repos.md` and
   `runbooks/register-repo.md`, `runbooks/README.md`, `METHOD.md` §7,
   `runbooks/collaboration.md` §8 and §9, `prompts/README.md`, and the header comment in
   `registries/repos.yml`) — **and `templates/repo-readme-template.md` with them**, which is a
   template but belongs in this group: it carries the `## Role in <project>` section the new
   runbook sends you to write into a repo that already exists. **The files that route to the new
   runbook come with them**: `AGENTS.md`, `runbooks/check-in.md`,
   `runbooks/dependency-supply-chain.md`, `runbooks/incident-postmortem.md`, and the three
   templates you author STEPs and substeps from — `templates/substep-prompt-template.md`,
   `templates/step-plan-template.md` and `templates/step-index-seed.md` — **and
   `templates/planning-session.md`**, whose repo-scaffolding step routes there too.
2. If you were planning to split a repo **only** in order to add a second contributor — stop.
   That rule is gone, and nothing replaces it.
3. Add `origin:` and `control:` to each row of your `registries/repos.yml` — **details at the end of
   this section.** Nothing rewrites the file for you.
4. **If any value in `registries/repos.yml` is wrapped across two lines, join it onto one** and
   quote it. `scripts/check.sh` now fails on a multi-line value — details at the end of this
   section. Nothing else in 1.8 can turn a passing run red on its own.
5. **Mono-repo-for-now only: check that `method-check.yml` is at your workspace root.** If it is
   not, the method-integrity gate has never run on your project — details below.
6. **Check the Title of every past Check-in STEP row in `prompts/STEP-index.md`.** The cadence
   helper now requires it to *begin* `Check-in` — details at the end of this section. Nothing
   rewrites your index for you, and a row it no longer recognises costs you the cadence line, not
   a failing check.
7. Nothing else. A project that never splits reads none of the splitting material.

**A bootstrap fix, with nothing for you to do.** 1.8 also fixes `init.sh` so that it refuses to run
anywhere but a fresh template checkout. Unpacking the template into a repository you already had and
running it there used to delete that repository's `.git` and every commit in it, silently. `init.sh`
runs once, when a project is created, and an existing project never runs it again — so no file of
yours changes and there is no action here. It matters only the next time you bootstrap a **new**
Throughstone project: do that from 1.8 or later.

The same release changes one bootstrap default, and again there is nothing to do. `init.sh`'s
interactive project-type question now defaults to private/proprietary rather than open source, so
pressing Enter through setup no longer licenses a project MIT without anyone naming a license. Your
project's posture was chosen when it was created and is recorded in `.throughstone/project-license`;
it does not change. Worth knowing only if you bootstrap another project from muscle memory.

**The Check-in STEP now has a title contract, and one row of yours may need renaming.**
`scripts/status.sh` measures the check-in cadence from the last `Done` STEP it recognises as a
check-in. It used to recognise one by looking for the words *check* and *in* anywhere in the
Title, which was wrong in both directions: a bug STEP called `Fix the check-in report generator`
reset the clock — and `runbooks/check-in.md`'s own Carry-forward step is what produces bug STEPs
named after the check-in that found them — while the requirement to use those words at all was
written down nowhere, so a descriptively-titled check-in was invisible. The rule is now stated, in
`METHOD.md` §5, `runbooks/check-in.md`, `templates/planning-session.md` and `prompts/README.md`:
**the row's Title begins `Check-in`**, optionally followed by a scope (`Check-in: phase 1`).
Markdown emphasis around it is fine, and matching ignores case.

Open `prompts/STEP-index.md` and look at every check-in row you already have. `Check-in`,
`Check-In`, `CHECK-IN` and `**Check-in**` all still count. Titles like `Mid-phase check-in`,
`Phase 1 check-in` or `Docs and test sweep` no longer do — rename them to lead with `Check-in`
and keep the old wording after it if you want it (`Check-in: mid-phase`). Nothing fails if you
skip this: `scripts/check.sh` does not police STEP titles, and the only consequence is that
`./doctor.sh status` reports "no Check-in STEP yet" and then tells you one is overdue.

**The rule that went away.** The method used to say a mono-repo-for-now project had to split before
taking on a second contributor. It gave two reasons and neither holds. The STEP-number push race
works exactly the same in a mono repo with a shared remote — what a team needs is *shared* remotes,
not *several* repos — and the overlap warning's mono fallback was already written, in the very
section that clause cited. **How many repos you have follows your architecture, not your
headcount.** If you already split for the old reason you have lost nothing and there is nothing to
undo; if you were about to, you no longer need to.

**Splitting, when you do want it.** `runbooks/splitting-repos.md` covers both cases behind one
routing block: splitting a code repo in two, and converting a mono-repo-for-now workspace to
multi-repo. It is a STEP, like the check-in, with a thin PLAN that points at the runbook rather than
authored substep prompts. The mechanic clones the whole repo and deletes forward, so **nothing is
rewritten**: both sides keep the full history as the same objects with the same SHAs, and
`git blame`, `git log --follow`, `git bisect` and every commit SHA you have recorded anywhere keep
resolving in the new repo on day one, and `git merge-base` resolves across the split once one repo
fetches the other. The cost is stated plainly in the file
— every new repo inherits every blob the origin ever committed, including deleted ones — and an
appendix covers purging history first when that matters.

- *Process docs* (`runbooks/splitting-repos.md`, `runbooks/register-repo.md`,
  `runbooks/README.md`, `METHOD.md` §7, `runbooks/collaboration.md` §8 and §9,
  `prompts/README.md`, `registries/repos.yml`'s header, `AGENTS.md`, `runbooks/check-in.md`,
  `runbooks/dependency-supply-chain.md`, `runbooks/incident-postmortem.md`, and the templates
  `repo-readme-template.md`, `substep-prompt-template.md`, `step-plan-template.md`,
  `step-index-seed.md` and `planning-session.md`): two new runbooks plus the edits that route to
  them —
  `METHOD.md` §7 gains the mono→multi special case (that STEP is
  branchless, and its number is reserved on trunk), `collaboration.md` §9 gains a mono path
  through solo→team including the warning not to run `scripts/setup-workspace.sh` in a mono clone,
  and `prompts/README.md`'s thin-STEP note now names two families rather than the check-in alone.
  `AGENTS.md`, `check-in.md`, `collaboration.md` §8 and the substep template stop describing a
  registry row and name the registration action; `check-in.md`,
  `dependency-supply-chain.md` and `incident-postmortem.md` carry the reachability wording; the
  two STEP templates carry the projection rule; and the planning session decides whether a repo
  the architecture names already exists by looking for a repository rather than by reading a
  README.
  **Five templates travel with this group even though §2's buckets call templates future-only.**
  `templates/repo-readme-template.md` gained the
  `## Role in <project>` augment form, which is what `runbooks/register-repo.md` sends you to when a
  repo already has a README, so a 1.7 copy of it leaves the new runbook pointing at nothing. The
  next three are what you author STEPs and substeps from: a 1.7 substep template still sends an
  agent off to write a registry row by hand, and the two 1.7 STEP templates carry no projection
  rule at all. `templates/planning-session.md` is the fifth, and it is the one that changes
  behavior — see below.
  Apply them as a coherent group; they reference each other. No `status.sh` change, and no split-
  specific check: 1.8's new `check.sh` checks read `registries/repos.yml` for its own consistency
  and shape, and nothing detects registry drift *after a split* — a row that still describes a
  folder that is now its own repo — which is accepted rather than overlooked.
- *Project state* (your existing `registries/repos.yml` rows and your repos): never auto-updated.
  `provenance:` is a new optional block recording that a repo was split out of another one — where
  it came from, and where the two histories part company. It is written **at** a split and only
  then, so existing rows do not gain it and a project that split before 1.8 does not backfill.

**Add `origin:` and `control:` to each of your repo entries.** 1.8 gives repo rows three new fields
— `origin:` (`created` | `adopted`, a fact written once), `control:` (`managed` | `external`, whether
Throughstone may write into that repo), and `provides:` (how each repo's README, licensing posture
and CI gate is actually met). The pulled `registries/repos.yml` header documents all three in full,
along with the default, the invariants, and the rules anything reading that file has to follow.

**The two worth adding by hand are `origin:` and `control:`**, because **a missing `control:` reads
as `external`** — control is a permission, and an unanswered permission is not a granted one, so the
method records the repo and writes nothing into it until somebody answers. Answering now means
nothing changes under you; a row you leave alone arrives unanswered and gets surfaced and asked
about rather than silently switched. Use `created` for a repo Throughstone made and `adopted` for one
that was already there when you pointed the method at it, and `managed` for each repo you want the
method to keep maintaining.

**`provides:` can wait for your next check-in.** It records what is in each repo rather than what you
have decided, so it is filled in by looking rather than remembering. A row whose `location` is not a
repository never carries it at all — in a mono-repo-for-now workspace a row pointing at a folder
inside the one repo is not one, and carries none until a split makes it a repo of its own.

**What the fields mean, and how to register a repo, are now written down.** `METHOD.md` §7 carries
the model — control is a permission, granted once for a whole repository and never per file; the
invariant that a repo Throughstone controls has its needs met, so an unmet need can only sit on one
it does not; the three needs and what "met" means for each; and the single ladder that runs per
need. Only the README has rungs there, because CI and licensing are met by *recording* what is
already in the repo — **the method never installs a CI gate and never applies a license to a repo it
did not create.** The new `runbooks/register-repo.md` carries the procedure, and everything that
changes the set of repositories your project has goes through it.

**Two rule changes ride along, and neither forces anything on you today.** STEP-1 work takes the
`step-0001-architecture` branch in **every** repository it writes into — not only the docs hub,
`prompts/` and the mono root, but a repository that already existed and is now under Throughstone's
control. And a repository the method only *references* never appears in a STEP's Repos projection: a
STEP is work Throughstone does, in repositories it controls. Both matter from the moment you mark a
repo `external`, or run a STEP that writes into an adopted one; until then there is nothing to
change.

**Your process docs now point at that procedure, and three of them behave differently because of
it.** Everything that used to send an agent off to write a `registries/repos.yml` row by hand —
`AGENTS.md`, the substep prompt template, `runbooks/collaboration.md` §8 — names the registration
action instead. None of them describes a row any more, which is what keeps them correct as the
fields change. The two STEP templates carry the projection rule above. Three things actually
behave differently:

- **Your next check-in sweeps repo READMEs by row rather than uniformly.** Where the row says
  Throughstone wrote that README, the sweep is what it always was — Overview, Setup / Running /
  Testing, and any `ARCHITECTURE.md`. Where Throughstone only added a section to someone else's
  README, the sweep is that section and nothing else. Anywhere else it edits nothing at all and
  asks one question: can someone standing in this repo still find their way back to the project?
  **The "do the setup steps still work from a clean checkout" check is deliberately gone for
  repos you do not own** — that is a judgement about somebody else's repository rather than about
  your connection to it. Two smaller shifts ride along: a registry row and its Architecture
  Overview entry now count as **one** thing that drifts, fixed by re-running the registration
  rather than by editing either side; and the licensing question is never re-asked per repo,
  because that posture lives in one project-wide file.
- **`runbooks/collaboration.md` §9 no longer stands up a remote for every repo.** Going solo to
  team, the create-a-remote-and-push-your-history step is now scoped to repos Throughstone
  created. As it stood, following it literally would have created a second remote for a
  repository someone else owns and pushed their history into it. Recording a remote a repo
  already has is unchanged, and every repo that has one still gets its `remote:` field.
- **The planning session no longer decides a repo exists by reading its README.** Its
  repo-scaffolding step used to count a repo as already there only if it had a registry row
  **and** a README whose role one-liner and Overview were filled in — so a real repository with a
  thin README was judged absent and scaffolded over, writing a stack, CI, an `.env.example`, a
  `.gitignore` block and possibly a license into somebody's existing work. It now asks whether the
  repo is already registered, and if it is not, whether there is a repository at that location —
  a work-tree root, not a folder that looks finished. Asking the registry first also means a repo
  you have registered but **not cloned on this machine** is never re-created. Where no repository
  is found, the step creates one exactly as before. Where one is found, **no stack wiring, no CI,
  no `.env.example`, no `.gitignore` block and no project `LICENSE`** go into it, and it is
  registered instead — what does land there is the registration action's call. Creating and
  registering are both a STEP's
  work, as they always were; the session decides and outlines. Adopt the reworded step.
  Nothing of yours is rewritten, and a first run on a fresh project behaves exactly as it did in
  1.7.

**Three read-only sweeps stop over-promising.** The check-in's full test run, the dependency
audit and the incident runbook's hunt for similar issues each asked for "all repos"; they now ask
for every repo you can reach, and for the ones you can't to be named. What that guards against is
not missing a repo — it is a partial sweep that reads as a clean one. If every repo your project
has is on your machine, nothing about these three changes for you.

Adding the fields is a **safe additive edit**: it inserts lines into each row and changes no existing
data. `registries/repos.yml` is your project's own record, like `inputs/inputs-index.md`, so it is
**never auto-overwritten**.

**What the doctor will say about that file after you pull 1.8.** `scripts/check.sh` reads
`registries/repos.yml` for the first time in this release, so it will report on rows it has never
looked at before. Three shapes of finding, and only one of them can fail your run:

- **A row with no `origin:` or `control:` is a warning**, listed by name, and a warning does not
  change the exit code. The message says those rows carry no control record. It is **not** a
  statement about how old your project is — nothing on disk records which version of the method you
  installed, so the doctor cannot tell a project written before these fields existed from one whose
  registration simply did not fill them in. Answering the two fields, as above, is what clears it.
- **A row that contradicts itself is a failure**: a status outside `ours` / `extended` / `theirs` /
  `N/A` / `gap`, an `origin:` or `control:` that is not one of its two values (a typo counts — it
  reads as neither), a `managed` repo recording a `gap`, an `external` repo recording `ours` or
  `extended`, or a `gap` or `N/A` with no note saying why. None of these can arise from leaving the
  file alone; each one needs a row that was written and is wrong.
- **A value written across more than one line is a failure.** This is the only finding here that can
  turn a run red without you having changed anything, so it is worth looking for before you upgrade:
  a long `description:` written as a YAML block scalar (`description: |`) is the likely case. Put the
  text on one line and quote it. The reason is not tidiness — the scripts that read this registry
  match line prefixes and know nothing about YAML nesting, so a wrapped value whose second line began
  `location: /srv/…` made `scripts/setup-workspace.sh` clone a repository into that path and exit
  successfully. Single-line values make that impossible rather than merely discouraged.

**Rows for repos that are not on your machine are skipped, counted, and said so** — "2 row(s) not
present on this machine". The doctor only judges what it can see, so a teammate with three of eight
repos cloned gets findings about those three and a count for the rest, rather than silence that
looks like a pass.

**Mono-repo-for-now? Your CI gate has probably never run.** `method-check.yml` ships inside the docs
hub, at `Code/<project>-docs/.github/workflows/`. In a multi-repo project the hub is its own
repository, so that is a repository root and the workflow is live from day one. In a mono-repo-for-now
project the workspace root is the repository and the hub is a folder inside it — and **GitHub reads
workflows only at a repository root**, so a workflow nested that deep never triggers. Unless you
followed the manual copy step (it is documented, but only in the workflow's own header comment and
`templates/ci/README.md`), the gate has been silently absent for the life of the project.

**Copy `Code/<project>-docs/.github/workflows/method-check.yml` to `.github/workflows/` at your
workspace root, and commit it.** No edit is needed: the workflow finds the doctor in either layout,
and from the root it also sees `prompts/`, so the STEP-index checks run too. Leave the hub's copy
where it is — that is the copy that gives the docs hub its own CI if you ever split. Expect the first
run to report findings that have been accumulating unseen. 1.8 places the file for you in **new**
mono projects; `init.sh` runs once, so nothing places it in a project that already exists.

Multi-repo projects have nothing to do here.

**A teammate whose workspace setup died part-way can now finish it.** If someone ran
`Code/<project>-docs/scripts/setup-workspace.sh` and it stopped with a `git clone` error, leaving the
workspace root with no `AGENTS.md`, no `CLAUDE.md` and no `doctor.sh`, that was one failing clone
taking the whole run down with it. **Pull 1.8 into the docs hub and run the script again.** Nothing
needs undoing first: repos already cloned are left alone, the pointer files are rewritten every run,
and the run now finishes whatever happens to the clones. Its closing line says how many repos did not
arrive, so fix the `remote:` or `location:` in `registries/repos.yml` — or clone that one repo by
hand — and re-run to pick it up.

**Look at any `location:` in your registry that points outside the workspace root.** An absolute
path, or one reaching out with `..`, is now reported and skipped rather than cloned into; before 1.8
the path was used verbatim, so a writable one put the repository outside the workspace silently. No
edit is required and nothing of yours is rewritten — but a repo registered that way is now one each
contributor clones onto their own machine once, rather than something the setup script fetches for
them. A `location:` inside the workspace root is unaffected, including one outside the `Code/*`
shell, and so is a repo already checked out where its `location:` points.

**Three generated docs need pulling, and that is the whole action.**
`ONBOARDING.md`, the docs hub's own `README.md` and §2's file-bucket table above were each
written when Throughstone only ever *created* a repo. 1.8 can also take on one that already
exists, where it writes at most two files: that repo's README and the `LICENSE-THROUGHSTONE`
notice — never CI, never a license. `ONBOARDING.md` also still described `setup-workspace.sh`
cloning before it writes the root pointer files, which is the order 1.8 reversed. Review the
three like the other process docs; nothing of yours is rewritten.

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

### 1.7.2 migration

**Templates and guidance text only — no behavior changes, and nothing you already produced is
rewritten.** Two edits to `templates/architecture-sessions/*.md` and three documentation fixes, all
*Templates for future use* under §2, so they affect work you do after pulling them.

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

Pull `templates/architecture-sessions/*.md`, `METHOD.md` §4 and §6, `inputs/README.md`,
`templates/architecture-doc-template.md`, and `runbooks/check-in.md` as a group. Nothing else is affected: no `status.sh` /
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
