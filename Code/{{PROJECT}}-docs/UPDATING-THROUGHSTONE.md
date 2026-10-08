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
- `prompts/README.md` carries the STEP-planning behavior for both local-profile values.
- `runbooks/collaboration.md` explains the multi-contributor local-profile expectation.

During an update, treat those old `overview.md` sections as legacy project-state drift:

1. Create or update root `.throughstone/local-user.md` for the active user, optionally using
   the old `overview.md` values as a starting point if they actually describe that user.
2. Remove the old personal-preference sections from `overview.md` only after confirming they
   are not project facts.
3. Do **not** migrate them automatically, by a script or by `doctor`: in a team, the old
   values may describe the original maintainer, not the active contributor.

`scripts/check.sh` warns when it sees these legacy sections. The warning is advisory and does
not fail the check.

### Next release migration

This section says only what to do. What changed, and why, is in the summary at the top of this
release's section of Throughstone's `CHANGELOG.md`.

**Staying on 1.x is fine. Upgrade if any of these apply:**

- **Your project is mono-repo-for-now.** Running `setup-workspace.sh` overwrites the root
  `CLAUDE.md`, `AGENTS.md` and `doctor.sh` your repository commits, and your CI gate may never have
  run.
- **Your project is multi-repo.** Setting up a workspace from the registry can clone a repo into the
  wrong place, or the wrong repo into a folder, and report success.
- **More than one person works on it.** Two ADRs can share a number without anyone being told.
- **A planning session will name a repo that already exists.** It can plan a scaffold over that
  repo's existing work.
- **`prompts/STEP-index.md` might go missing on a machine.** The status helper then says to run
  `./init.sh`, which deletes a mono project's repository history.
- **You deferred architecture work**, such as a core session left `Deferred` or a `Coverage:` line
  other than `full`. It can drop out of every check-in.
- **Your check-ins run on a machine without every repo, or your project has several test suites.** A
  check-in can report a green suite, or a clean dependency audit, when some of it never ran.
- **Your STEP index has an unusual row**: a blank or dashed Status, an HTML comment, a title
  containing "check-in" or "checking" that isn't one, or STEP-1 `Done` with a substep still open.
  The status helper can name the wrong next STEP, or count a check-in that never ran.

This section starts from 1.7.1. On an older release, do the earlier sections first, oldest first,
and skip any step they mark as superseded.

1. **Every project: bring over the files this release changes.** Copy each file below from the
   scaffold over yours, or merge it by hand where you've edited yours. Paths are from the docs hub,
   except `prompts/README.md`.
   - Work as §6 says: from clean working trees, on a branch. This release changes `METHOD.md`,
     `AGENTS.md` and `status.sh`, so §7 makes the upgrade a tracked STEP.
   - Scripts: `scripts/apply-project-license.sh`, `check.sh`, `doctor.sh`, `links.sh`,
     `setup-workspace.sh` and `status.sh`.
   - CI workflow: `.github/workflows/method-check.yml`.
   - Process docs: `AGENTS.md`, `BOOTSTRAP-PROMPT.md`, `METHOD.md`, `ONBOARDING.md`, `README.md`
     (the docs hub's own) and `UPDATING-THROUGHSTONE.md`; `coding-standards/csharp.md`, `go.md`,
     `python.md` and `typescript.md`; `inputs/README.md`; `registries/README.md`;
     `reports/README.md` and `reports/test-results/README.md`; `runbooks/README.md`, `check-in.md`,
     `collaboration.md`, `dependency-supply-chain.md`, `incident-postmortem.md`, `register-repo.md`
     (new), `release-deploy.md`, `secrets-rotation.md`, `security-review.md`,
     `security-review-s0-checklist.md`, `security-review-s1-checklist.md`,
     `security-review-s2-checklist.md` and `splitting-repos.md` (new); and `prompts/README.md`, at
     the workspace root.
   - Templates: `templates/architecture-doc-template.md`; all seventeen files in
     `templates/architecture-sessions/`; `templates/ci/README.md` and `code-repo-ci.yml`;
     `templates/env-example.txt`; `templates/licenses/README.md`; `templates/overview-template.md`;
     `templates/planning-session.md`; `templates/repo-readme-template.md`;
     `templates/reports/check-in-report-template.md`;
     `templates/reports/security/s0-security-baseline-report-template.md`,
     `s1-security-sweep-report-template.md` and `s2-security-audit-report-template.md`;
     `templates/reports/test-results/test-results-summary-template.md`;
     `templates/step-index-seed.md`; `templates/step-plan-template.md`; and
     `templates/substep-prompt-template.md`.
   - Bring the whole list. These files point at each other, so a partial set sends agents to text
     that isn't there.
   - Fill in the placeholders setup filled in when your project was made: `PROJECT`,
     `PROJECT_DESCRIPTION` and `TRUNK_BRANCH`, each written in double braces, become your project's
     slug, its one-line description and its trunk branch. Your current copies show the values, so
     read them before you copy over them. Leave every other placeholder as it is:
     `templates/licenses/README.md` keeps `YEAR` and `HOLDER` on purpose.
   - Copy a file over yours only where yours still matches 1.7.1's, placeholders filled in; §4 calls
     that *upstream-only*, and a file you've edited *diverged*.
   - Gotcha: the six scripts must stay executable. If one isn't after the copy, `chmod +x` it.
   - Check: each file matches the scaffold's apart from the placeholders and any edits of yours you
     merged, and `./doctor.sh help` mentions `--check-in`.

2. **Every project: add `registries/input-captures.yml`, and replace the comments in
   `registries/repos.yml` with the scaffold's; a mono-repo-for-now project with no
   `registries/repos.yml` copies in the scaffold's whole `registries/` folder.**
   - Copy in the scaffold's `registries/input-captures.yml`, which holds no captures yet. Sessions
     add to it from now on; if you have `inputs/inputs-index.md`, step 14 carries that ledger's
     `Superseded` rows into it.
   - In `registries/repos.yml`, replace two comment blocks with the scaffold's: the header above
     `repos:`, and the block holding the commented example row, which starts
     `# Service / app / library repos get added here`. Leave every row as it is, wherever that block
     sits among them; steps 3 and 4 edit the rows.
   - Mono-repo-for-now with no `registries/repos.yml`: 1.x let a mono project leave `registries/`
     out. Copy in the scaffold's whole `registries/` folder, and keep both seeded rows: the docs hub
     and `prompts/` are folders inside your one repository, and the registry lists them anyway.
     Delete a row only if it names something your project doesn't have. Step 4 adds the third row,
     for the workspace root.
   - Each file you copy, and each comment block you replace, holds the `PROJECT` placeholder (in
     double braces): fill it in as step 1 says.
   - Gotcha: a comment at the end of a row's line, like the one after the docs hub's `type:`, is
     part of that row. Leave it.
   - Check: run from the docs hub, `git diff registries/repos.yml` changes only comment and blank
     lines (where you copied the folder in, `git status` shows it as new instead), and nothing in
     `registries/` still holds the `PROJECT` placeholder.

3. **Every project: check each row of `registries/repos.yml`.**
   - Each row starts with its `- name:` line, and every value is on one line: no lists.
   - Nothing follows a `- name:`, `location:` or `remote:` value, because a `#` there is read as
     part of the value. A row copied from 1.x's commented example has `# team mode: …` after its
     `remote:`; move that note onto a line of its own, or delete it.
   - Values are in double quotes or none.
   - Each `location:` is a path relative to the workspace root: it never starts with `/` or `~`, and
     has no `..` segment. Move a repo that breaks this into the workspace and update its row. If it
     can't move, leave it where it is, put a symlink at a workspace-relative path pointing at it,
     and register the symlink's path.
   - Gotcha: values are taken literally, so `~/lib` and `$HOME/lib` are folder names, not paths into
     a home directory.
   - Check: `./doctor.sh check --check-in` reports no row it couldn't read and no row without a
     `location:`.

4. **Every project: declare the layout in `registries/repos.yml`, and, mono-repo-for-now only, add a
   row for the workspace root.**
   - Add `layout: mono` or `layout: multi` at the left margin, above `repos:`, with a blank line
     between. One line only, and never below the rows.
   - Mono-repo-for-now: add this as the first row under `repos:`, leaving out the `remote:` line if
     the repository has no remote yet:
     ```yaml
       - name: "<your-project>"
         location: "."
         remote: "git@example.com:TEAM/<your-project>.git"
         type: mono
         added_as: created
         description: "The workspace root: the one repository this project lives in until it is split."
     ```
   - Gotcha (mono): with the line but not the row, the check-in fails, so make both edits together.
   - Gotcha (mono): a row that already has a `remote:` of its own is a separate repository, so the
     project isn't mono-repo-for-now in practice. Decide which layout you're in before declaring
     one: `mono` fails on that row and points you to `runbooks/splitting-repos.md` Case 2.
   - Gotcha: once the line is there, the check-in warns about each repo no recorded remote covers,
     and a 1.x registry often has rows without one. For each, record the URL; or create a private
     remote, push to it, then record it; or decide local-only is fine. Nothing records that
     decision, so the warning comes back at every check-in.
   - Check: `./doctor.sh check --check-in` no longer warns that the registry declares no layout, and
     shows no registry `[FAIL]`.

5. **Multi-repo only: on each machine `setup-workspace.sh` set up, run it again** from the workspace
   root: `Code/<project>-docs/scripts/setup-workspace.sh`.
   - It rewrites the root `AGENTS.md`, `CLAUDE.md` and `doctor.sh` (the older pair lacks the
     paragraph that makes "Read `AGENTS.md` and follow it" an instruction), leaves repos already
     cloned alone, and clones any that are missing.
   - Gotcha: a location holding a `.git` and nothing else is an empty clone, now reported. Fix the
     branch on that remote, delete the empty directory, and run again. A location where someone ran
     `git init` and never committed is reported too: move it aside, because the files in it are
     theirs.
   - Check: the run ends with "Done.", no `skipped:` or `Not cloning:` line, and no count of repos
     that didn't arrive.

6. **Multi-repo only: delete the `.gitignore` at the workspace root, on any machine that has one.**
   - It's the template's own, which 1.x's `init.sh` left there. The workspace root is in no
     repository, so git never reads the file, and each repo keeps its own `.gitignore`. But a search
     tool that reads ignore files applies it from the root to every repo below, so files such as a
     `TODO.md` in the docs hub don't show up.
   - Usually only the machine the project was set up on has one: `setup-workspace.sh` doesn't write
     it.
   - Gotcha: anything you added to it never applied to git. Copy any line a repo needs into that
     repo's own `.gitignore` before you delete the file.
   - Check: from the workspace root, `ls -a` lists no `.gitignore`.

7. **Mono-repo-for-now only: copy `method-check.yml` to `.github/workflows/` at the workspace root,
   and commit it.**
   - Copy the docs hub's `.github/workflows/method-check.yml`, which step 1 brought up to date, over
     any copy already at the root. GitHub reads workflows only at a repository root, and in this
     layout the docs hub is a folder, so unless someone copied the file to the root by hand, your CI
     gate has never run.
   - If you already have a root copy, replace it: 1.x's runs a root `scripts/check.sh` of your own,
     where there is one, in place of the doctor. The new copy needs no edit: it runs the docs hub's
     doctor, and from the root it reaches `prompts/` too, so the STEP-index checks run as well.
   - Leave the docs hub's copy where it is. It gives the docs hub CI of its own if the project is
     ever split.
   - Gotcha: the first run checks work no gate has seen before, so it may fail. It runs the same
     checks as `./doctor.sh check`, so push once that ends with `RESULT: OK` in step 20.
   - Gotcha: the test workflows your code folders were stamped with, from
     `templates/ci/code-repo-ci.yml`, never run in this layout either, and the root gate runs the
     method checks, not your tests. Leave them stamped and configured for a split. To gate tests
     before then, add a root copy with one job per code folder, as `templates/ci/README.md` §2 says.
   - Check: from the workspace root, `git ls-files .github/workflows` lists `method-check.yml`, and
     once you push to GitHub, the commit shows a `method-check` run.

8. **Mono-repo-for-now only: add two lines to the `.gitignore` at the workspace root, and commit
   it.**
   - Add them at the end of the file, in this order, so the second keeps the folder's `.gitkeep`:
     ```gitignore
     /Upcoming Prompts/*
     !/Upcoming Prompts/.gitkeep
     ```
   - In this layout the workspace root is the repository, so without them a `git add -A` commits the
     PLAN and substep prompts of the STEP in flight, which stay on the machine of whoever runs the
     STEP until it's archived into `prompts/`.
   - Gotcha: the lines untrack nothing. From the workspace root, `git ls-files "Upcoming Prompts"`
     lists what's still tracked. To untrack a sheet, `git rm --cached` it and commit: your copy
     stays on disk, but a teammate who pulls that commit loses their copy if they haven't edited it,
     so leave each sheet to whoever owns its STEP.
   - Check: `git ls-files "Upcoming Prompts"` lists only `.gitkeep` and any sheet you've left to its
     owner, and a new file in `Upcoming Prompts/` doesn't show in `git status`.

9. **Mono-repo-for-now only: bring the root `CLAUDE.md` and `AGENTS.md` up to date, and commit
   them.**
   - In each, replace everything from the line starting `The canonical agent context` to the end
     with the same text from the scaffold's root file of the same name, and fill in the `PROJECT`
     placeholder (in double braces) as step 1 says.
   - In this layout both files are committed in your one repository, but 1.x's text calls the docs
     hub a repo and says they're per-machine and not versioned. The new text says that only of a
     multi-repo project, where step 5 rewrites them instead.
   - Gotcha: copy nothing from above that line. The scaffold's root files open with a block for
     Throughstone's own authors, between `THROUGHSTONE-TEMPLATE-GUARD` markers, which setup removes
     from every project.
   - Gotcha: the replacement also deletes anything added below that line since setup, such as notes
     for your agent. Move such text above that line first, so it survives and the file still ends as
     the Check says.
   - Check: each file says that in mono-repo-for-now it is committed in the root repo, and ends with
     *"Read AGENTS.md and follow it."*; neither still holds the `PROJECT` placeholder; and
     `git status` lists neither file.

10. **Every project: put a `NEXT-CHECK-IN` line in `overview.md`, in place of any `CHECK-IN-CADENCE`
    line.**

11. **If a row of `prompts/STEP-index.md` has a Status that's blank or only dashes: write its real
    status.**

12. **If `prompts/STEP-index.md` lists the substeps of an in-flight STEP other than STEP-1: move
    that list into the STEP's PLAN.**

13. **If you deferred architecture work: make sure a `registries/risks.yml` row covers each
    deferral.**

14. **If you have `inputs/inputs-index.md`: carry its `Superseded` rows into
    `registries/input-captures.yml`, then archive or delete it.**

15. **Every project: delete the `Version` and `Status` columns from the index in
    `architecture/README.md`.**

16. **Every project: update the ADR-number scan in `adr/README.md`, and, in a team, check its
    *Who accepts an ADR* line.**
    - `adr/README.md` is your project's own file, so step 1 doesn't replace it. Its 1.x scan names
      the file as `adr/README.md`, a path from inside the docs hub, so run from the workspace root,
      where agents start, it scans nothing and reports no duplicate.
    - Replace two parts with the scaffold's: the bullet under `## Conventions` that starts
      *Reserve the number*, which now sends a team to `runbooks/collaboration.md` §6, where the scan
      runs from the workspace root; and the note under `## Registry`, which pointed at the old scan.
      Neither holds a placeholder.
    - In a team, check the *Who accepts an ADR* line. `AGENTS.md` now gives an agent the team rules
      only when that line names someone other than `_solo author_`, or agents work in parallel. If
      more than one person works on the project and the line still reads `_solo author_`, record
      your rule there, as `runbooks/collaboration.md` §9 step 3 says.
    - Gotcha: if you've reworded that bullet, keep your wording and fix only its command, naming the
      file as `Code/<project>-docs/adr/README.md`, as `runbooks/collaboration.md` §6 does.
    - Check: the bullet in `adr/README.md` points at `runbooks/collaboration.md` §6 or, where you
      kept your own wording, its scan command names `Code/<project>-docs/adr/README.md`; in a team,
      the *Who accepts an ADR* line names your rule.

17. **If a script or CI job of yours runs a Throughstone helper: check the arguments it passes and
    the output it reads.**

18. **Optional, every project: widen the `.claude` line in each repo's `.gitignore`.**
    - Replace the line `.claude/settings.local.json` with the three lines a new project gets, and
      leave every other line as it is:
      ```gitignore
      **/.claude/*.local.json
      **/.claude/#*#
      **/.claude/*~
      ```
    - The old line ignores that one file at the repo's top level. The new ones also ignore an
      editor's lock or autosave copy of it, and any of these in a subfolder: in mono-repo-for-now,
      an agent started inside a code folder writes its own `.claude/` there. A shared
      `.claude/settings.json` still commits.
    - In multi-repo, do this in the docs hub's, `prompts/`'s and each code repo's `.gitignore`; in
      mono-repo-for-now, only in the one at the workspace root, whose lines cover every folder below
      it. Leave a repo the project took in that already existed: its `.gitignore` is its own.
    - Gotcha: a code repo a 1.x planning session made may have no `.claude` line to replace. Add the
      three lines anyway.
    - Gotcha: the lines untrack nothing. A per-machine file already committed, such as a code
      folder's `.claude/settings.local.json` in mono-repo-for-now, stays tracked until you
      `git rm --cached` it and commit. Your copy stays on disk, but a teammate who pulls that commit
      loses theirs if they haven't edited it, so tell them first.
    - Check: from the top of each repo you changed,
      `git check-ignore -v sub/.claude/settings.local.json` prints the `**/.claude/*.local.json`
      line. The path needn't exist.

19. **Optional, each contributor: check the communication style in your root
    `.throughstone/local-user.md`.**

20. **Every project: run the checks** from the workspace root: `./doctor.sh check`,
    `./doctor.sh check --check-in`, `./doctor.sh links` and `./doctor.sh status`.
    - A `[FAIL]` from check 5 because two ADR files share a number: do what its hint says,
      renumbering the file added later and giving it its own row in `adr/README.md`.
    - A `[FAIL]` from check 4 naming a doc you lifted from `inputs/`: add the header field it lacks.
    - A `[WARN]` from check 1, 2, 3 or 9 that says it had nothing, or not everything, to read: no
      STEP rows, no ADR registry table, STEP rows under no Status column, or no session-template
      folder. That was already wrong: restore the missing file, folder or table header from git
      history.
    - `--check-in` adds check 10, the registry. Its warnings about repos no recorded remote covers
      are the ones step 4 describes; a `[FAIL]` there goes back to step 3 or 4.
    - A `[FAIL]` from `links` on a saved S0, S1 or S2 security report: its link to its checklist
      came from a 1.x template. Write the checklist's path as plain text instead, as the new
      templates do. `links` no longer reads `inputs/`, so a link inside an input no longer fails it.
    - Check: `check`, `check --check-in` and `links` each end with `RESULT: OK`, and the line under
      `Check-in:` from `status` names a STEP or a date, not "none scheduled".

That's the whole upgrade.

### 1.7 migration

**Upgrading from 1.6? Start here.** This release rewrites no project files. Only two defaults
shift, and only once you pull the new tooling/templates: the doc-maturity ladder and the check-in
cadence. Fast path:

1. Pull the process docs + tooling as one review-required group (`METHOD.md`,
   `runbooks/check-in.md`, `templates/planning-session.md`, `scripts/status.sh`, `scripts/check.sh`).
2. Want the old check-in window (DUE 10 / OVERDUE 20)? Add `<!-- CHECK-IN-CADENCE: 15 -->` to
   `overview.md`; otherwise omit it to take the new default of 20 (DUE 15 / OVERDUE 25).
   **Superseded in the next release** — the cadence setting is gone and `overview.md` records
   when the next check-in is due instead. Going straight to the next release? Skip this step and
   follow that release's section.
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

**Deferred-coverage check-in sweep.** *(Superseded in the next release, which retires the sweep
and brings a deferred area back through a `registries/risks.yml` row — read that release's section
instead if you are upgrading past 1.7.)*

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
  sequence work-item, plus the repo-scaffolding work-item's "first STEP is scaffold" line, is now milestone-relative —
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

**Project-selectable check-in cadence.** *(Superseded in the next release, which replaces the
setting with a recorded `NEXT-CHECK-IN` line — read that release's section instead if you are
upgrading past 1.7.)*

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

**Workspace model accepts in-place repos.** *(Superseded in the next release, where a `location:`
is always a path relative to the workspace root — read that release's section instead if you are
upgrading past 1.7.)*

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

### 1.7.1 migration

**Upgrading from 1.7.0?** A small follow-up that gives the `inputs/` folder a lifecycle. It rewrites
no project files and is greenfield-inert — the new ledger simply starts empty. Fast path:

1. Pull the process docs as one review-required group (`AGENTS.md`, `METHOD.md` §4,
   `runbooks/check-in.md`, `templates/architecture-sessions/01-system-overview.md` and
   `03-architecture-overview.md`, `templates/substep-prompt-template.md`,
   `templates/planning-session.md`, `templates/reports/check-in-report-template.md`).
2. Add the ledger: copy the scaffold's empty `inputs/inputs-index.md` (and the updated
   `inputs/README.md` guidance with it), then list any inputs you already have as `Live`.
   **Superseded in the next release** — the ledger is replaced by `registries/input-captures.yml`
   and the check-in's inputs sweep is gone. Going straight to the next release? Skip this step and
   follow that release's section.
3. Nothing else now. `inputs/archive/` is created only when you first retire an input, and the next
   check-in's inputs sweep is what surfaces a superseded input for a retire/keep decision.

The change establishes that **inputs are point-in-time** and `architecture/` is the living truth:
where a generated `architecture/` / `adr/` doc covers the same ground as an input, the generated doc
wins, and architecture-grade inputs are lifted into `architecture/` (a spec often a whole-file copy
or a light reformat). This is **low-friction: nothing is auto-rewritten**, and the §2 file-bucket
rules apply unchanged.

**Inputs lifecycle.** *(Superseded in the next release, which replaces the ledger with a capture
log and retires the check-in's inputs sweep — read that release's section instead if you are
upgrading past 1.7.1.)*

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

Throughstone ships no updater tool, so an update is done by hand:

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
   rules in §6 and §7, then run `./doctor.sh check`.

## 4. Compare Model

For every scaffold-managed file, compare three versions:

| Version | Meaning |
|---------|---------|
| **base** | the file as your project received it, in the Throughstone release it was built from |
| **local** | the file currently in this project |
| **upstream** | the file in the target Throughstone release |

Classify the result:

| Classification | Meaning | Default action |
|----------------|---------|----------------|
| **already-current** | `local == upstream` | Report only. |
| **upstream-only** | `local == base`, upstream changed | Candidate for apply, still review risk. |
| **local-only** | local changed, upstream unchanged | Keep local; no update needed. |
| **diverged** | local changed and upstream changed | Manual review or merge; do not auto-apply. |
| **baseline-unknown** | the base cannot be found or verified | Report only; require manual review before any baseline is adopted or update is applied. |
| **protected** | file is project-owned or generated | Never auto-apply. |

Use precise wording: **"unchanged locally"** is acceptable; **"safe to apply"** is not.
Do not treat today's local file as the base. Mark a file `baseline-unknown` unless it can be
checked against the release your project was built from, with your project's name in place of
the placeholder, or the user explicitly adopts a reviewed file as the new baseline.

## 5. Mechanical Risk Signals

Flag at least these in the report:

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

Any one of them makes the change review-required, whatever the release notes say.

## 6. Apply Rules

Only apply when all of these are true:

- user explicitly requested apply
- every affected repo has a clean working tree and index before any branch is created or switched
  and before any file is written
- the upstream release or ref was chosen
- file is not protected
- file is either `upstream-only` with a verified baseline or the user selected a manual merge
  result
- all files in the required update group are included

Branch rule:

- If the update meets the STEP threshold in §7, reserve a STEP and use the normal
  `step-NNNN-short-name` branch.
- If the update does not meet that threshold, use a dedicated scaffold-update branch so the
  change is still reviewable and easy to roll back.

After apply:

1. Run the docs hub checks (`./doctor.sh check`).
2. Preserve the update report in the branch or commit message.
3. Tell the user what changed, what was skipped, and which manual review items remain.

## 7. When To Make It A STEP

Make a tracked STEP when the update:

- changes `METHOD.md`, `AGENTS.md`, `status.sh`, collaboration rules, or STEP/ADR numbering
- touches more than one repo
- changes CI behavior
- requires manual merge decisions
- changes how future architecture sessions or planning sessions behave
- would affect an active team

The STEP's PLAN can be thin: point to this guide, list the update groups under review, and
define done as "report reviewed, selected updates applied, checks passed, and skipped/protected
files recorded."
