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
- `prompts/README.md` carries the STEP-planning behavior for both local-profile values.
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

**Upgrading from 1.7? Nothing of yours is rewritten, and there are three things to look at in
`registries/repos.yml`** — **whether any `location:` points outside the workspace root**, which 1.7
allowed and this release does not, **whether anything follows a `- name:`, `location:` or `remote:`
value**, which 1.7's example row did, and, **if your project is mono-repo-for-now, whether the
workspace root has a row at all** — **plus, for a mono-repo-for-now project, one thing to check**:
whether your CI gate has ever actually run — **and one line to change** in `overview.md`, where the
check-in cadence setting is replaced by the date or STEP your next check-in is due, **and, if your
project is mono-repo-for-now, two lines to add** to the `.gitignore` at your workspace root. Beyond the fast path below, nothing is
required of you unless you are about to split a repository. The release adds a runbook for that, repeals one rule, and writes down
how a repo is brought into a project at all — in a second new runbook. Fast path:

1. Pull the process docs as one review-required group (the new `runbooks/splitting-repos.md` and
   `runbooks/register-repo.md`, `runbooks/README.md`, `METHOD.md` §3, §5, §7 and §10,
   `runbooks/collaboration.md` §6, §8 and §9, `prompts/README.md`, `registries/README.md`, and the
   header comment in `registries/repos.yml`) — **and `templates/repo-readme-template.md` with them**, which is a
   template but belongs in this group: it carries the `## Role in <project>` section the new
   runbook sends you to write into a repo that already exists. **The files that route to the new
   runbook come with them**: `AGENTS.md`, `runbooks/check-in.md`,
   `runbooks/dependency-supply-chain.md`, `runbooks/incident-postmortem.md`, and the three
   templates you author STEPs and substeps from — `templates/substep-prompt-template.md`,
   `templates/step-index-seed.md` — **and `templates/planning-session.md`**, whose repo-scaffolding step routes there too, **and
   `templates/reports/check-in-report-template.md`**, which gains the Deferred Coverage table the
   updated `check-in.md` now tells you to fill in.
2. If you were planning to split a repo **only** in order to add a second contributor — stop.
   That rule is gone, and nothing replaces it.
3. **Check every `location:` in `registries/repos.yml`.** One that points outside the workspace
   root — an absolute path, or one reaching out with `..` — no longer works, and 1.7 said it was
   allowed. **Details at the end of this section**; this is the only change here that can leave your
   registry describing a workspace nobody else can reproduce. **While you are in each row, check
   that nothing follows a `- name:`, `location:` or `remote:` value** — a row copied from 1.7's
   commented-out example carries a note after its `remote:`, which has kept that repo from cloning
   on anyone else's machine all along; details in the same place.
4. **Mono-repo-for-now only: add a row for the workspace root** to `registries/repos.yml`, or the
   new check-in warning will be wrong about every repo you have — details at the end of this
   section.
5. **Mono-repo-for-now only: check that `method-check.yml` is at your workspace root.** If it is
   not, the method-integrity gate has never run on your project — details below.
6. **Put a `<!-- NEXT-CHECK-IN: STEP-<number> -->` line in your `overview.md`** — the STEP you
   want your next check-in at — replacing the `CHECK-IN-CADENCE` line if you have one. **Do this
   even if you never set a cadence**, or the helper will tell you nothing is scheduled on every
   run. Details just below.
7. **If a wrapper or CI step of yours calls `check.sh`, `status.sh`, `links.sh`,
   `setup-workspace.sh`, `apply-project-license.sh` or `./doctor.sh help` with a stray argument**,
   it will now print the argument and exit 2 instead of ignoring it. Every valid invocation is
   untouched.
8. **Mono-repo-for-now with no `registries/` directory?** 1.7 let you opt out, by `--registries=no`
   or by answering no to the interactive question, and only in that layout. Nothing in this section
   about the registry applies until you restore one: copy `registries/` from the scaffold, then
   replace `{{PROJECT}}` with your project slug throughout and delete any seeded row that does not
   describe a repo you have. The flag is deprecated in this release and the directory now always
   ships.
9. **Pull the local-profile group as one review-required set** — four of these travel with item
   1's group already, so pull them once. `BOOTSTRAP-PROMPT.md` Stage 0,
   `METHOD.md` §4, `ONBOARDING.md` §3, `AGENTS.md`, `prompts/README.md`,
   `templates/step-plan-template.md`, `templates/substep-prompt-template.md`,
   `templates/planning-session.md` and all sixteen `templates/architecture-sessions/` files that
   carry the calibration blockquote, plus `templates/architecture-sessions/14-cross-cutting-review.md`,
   which carries a shorter version of the same text. The experience level and the communication
   style now do one job each — the level sets how much technical background an agent may assume,
   the style sets how much reasoning comes with a decision — where the old text let the level
   decide both. **Nothing of
   yours is rewritten and no value is re-keyed**: your `.throughstone/local-user.md` keeps working
   as it is, and the stored tokens stay valid. **What does change is how your sessions sound.**
   Level 3 used to force terseness on its own, so set the style to Terse if that is what you
   want back; Levels 1-2 used to force a why-explanation, so set the style to at least Normal if
   you want that back. Because the communication style had no defined behaviour before this
   release, other old combinations have no exact equivalent. Two cosmetic
   notes: the level's self-report labels changed wording, so an existing profile keeps its old
   label until its owner edits it, which is harmless; and `ONBOARDING.md` §3 no longer repeats the
   two questions or the profile's file shape — it points at `BOOTSTRAP-PROMPT.md` Stage 0, which
   already owned both. If you have hand-edited any of these files, take the `METHOD.md` §4 and
   `BOOTSTRAP-PROMPT.md` Stage 0 changes first; every other file in the group restates those two.
   These templates travel with the group even though §2's buckets call templates future-only: a
   1.7 copy still tells an agent to explain a question's *what* and *why* together at Levels 1-2,
   which is half of the coupling this item removes.
10. **Mono-repo-for-now only: add two lines to the `.gitignore` at your workspace root** —
    `/Upcoming Prompts/*`, then `!/Upcoming Prompts/.gitkeep` below it — and commit it. In that
    layout the root is the repository, so without them a plain `git add -A` commits the PLAN and
    substep prompts of the STEP in flight, which the method treats as per-machine scratch until the
    STEP is archived into `prompts/`. Then, from the workspace root, run `git ls-files "Upcoming Prompts"`: the new lines
    untrack nothing, so anything listed besides `.gitkeep` is still tracked. To untrack a sheet
    nobody meant to commit, `git rm --cached` it and commit — your copy stays on disk, but a
    teammate who pulls that commit loses an unedited copy of theirs, so leave each sheet to whoever
    owns its STEP.
11. **If `./doctor.sh check` now fails a Status that is only dashes, or blank**, write that STEP's or
    substep's real status in `prompts/STEP-index.md`. The doctor used to skip such a row as though
    it were the table's separator line, and `./doctor.sh status` still does — so until it is fixed,
    the helper answers as if the row were not in the index at all. A project whose statuses are all
    filled in sees no change.
12. Nothing else. A project that never splits reads none of the splitting material.

**A bootstrap fix, with nothing for you to do.** 1.8 also fixes `init.sh` so that it refuses to run
anywhere but a fresh template checkout. Unpacking the template into a repository you already had and
running it there used to delete that repository's `.git` and every commit in it, silently. `init.sh`
runs once, when a project is created, and an existing project never runs it again — so no file of
yours changes and there is no action here. It matters only the next time you bootstrap a **new**
Throughstone project: do that from 1.8 or later, where the interactive project-type question also
defaults to proprietary rather than open source, so pressing Enter through setup no longer
licenses a project MIT without anyone naming one. Your own posture was chosen when this project was
created, is recorded in `.throughstone/project-license`, and does not change.

**A finished STEP-1 is no longer sent back into architecture, and there is nothing for you to do.**
`./doctor.sh status` walks `METHOD.md` §10's rules in order and stops at the first one that
matches. The rule about open STEP-1 substeps sat above the point where the helper read the STEP-1
row's own status, so a project whose STEP-1 row says `Done` while a session row is still `Planned`
was told *"Architecture (STEP-1) in progress — run STEP-1.N"*. Because that rule stops the walk,
the answer never changed again: a STEP `In progress` twenty STEPs later printed the same line, and
the STEP actually in flight was invisible to the helper. **The row now decides.** Once STEP-1 reads
`Done`, an open substep is no longer resolvable and the helper answers from the rules below it —
the planning session, or whatever STEP your index says is next. The mirror case is unchanged:
substeps all final while the row is still open still tells you to close STEP-1 out. Nothing of
yours is rewritten, and no row needs renaming; if you flipped session rows to `Done` only to get a
sensible answer out of the helper, you no longer need to. Optional sessions left `Deferred` are
swept by the check-in either way — `runbooks/check-in.md`'s conditional-session coverage
enumerates every conditional template and asks for a current disposition each time, without
consulting the STEP-1 row.

**The link checker no longer reads `inputs/`, and there is nothing for you to do.** A document
copied into `inputs/` or `inputs/archive/` with a relative link to a path your workspace does not
have used to fail `./doctor.sh links` for good: the method keeps inputs as they arrived, so there
was nothing you were allowed to fix, and moving the file to the archive changed nothing.
`scripts/links.sh` now skips that folder and everything under it, as it already skipped
`templates/`, so a link check that was red only for that reason goes green with nothing of yours
changed. A link *to* an input from a doc it does check is still checked. `AGENTS.md`,
`ONBOARDING.md` §4, `inputs/README.md` and `runbooks/splitting-repos.md` each gain one sentence
saying so.

**A doctor check that read nothing now warns instead of passing, and there is nothing for you to do
unless it warns.** `./doctor.sh check` used to pass its duplicate-STEP, duplicate-ADR, status and
conditional-template checks when they found nothing to read — an emptied `prompts/STEP-index.md` or
`adr/README.md`, a STEP table whose `Status` header had been renamed, or a missing
`templates/architecture-sessions/` folder. `scripts/check.sh` now prints a `[WARN]` for each. A
project whose files are intact sees no new warning: no ADR yet still passes, and so do conditional
templates you deleted on purpose. If one of the new warnings does appear, it is describing something
that was already wrong — usually a file, folder or table header that git history can restore.
Warnings never change the doctor's exit code, so no CI run turns red. If anything of yours reads the
doctor's pass lines word for word, three of them now end in a row count in parentheses.

**`private` and `proprietary` now mean two different things, and if you script `init.sh` there is
one rename.** `private` refers to repository visibility and nothing else; `proprietary` is the
licence posture. They were the same word in two unrelated questions — the licence question offered
"Private / proprietary" while a later one offered "1) Private" for who can see the repository — and
they are genuinely independent: a private repo can carry MIT, and a public repo can be proprietary.

- **Nothing in your project changes.** Your posture is recorded as `Proprietary` in
  `.throughstone/project-license` and always was; that spelling has not moved. `init.sh` runs once,
  when a project is created, and an existing project never runs it again.
- **If you have a wrapper, alias, or CI job that creates projects with `--license=private`, write
  `--license=proprietary`.** The old spelling still works and produces exactly the same project, so
  nothing breaks today — but it now prints a deprecation notice naming the new one, and it will be
  removed in a future release. `INIT_LICENSE=private` is the same story.
- **`--visibility=private` is unaffected** and stays as it is. That is the flag `private` now
  belongs to.

**The check-in is scheduled now, not calculated — one line of your `overview.md` changes.**
1.7 gave you a cadence setting, `<!-- CHECK-IN-CADENCE: N -->`, and `scripts/status.sh` combined it
with the last `Done` STEP whose Title looked like a check-in to work out whether you were due. Both
halves are gone. The helper reads one line that simply says when the next check-in is:
`<!-- NEXT-CHECK-IN: … -->`, holding either a STEP number (`STEP-45`) or a date (`2026-11-15`).

**Do this once.** Open `overview.md`, delete the `CHECK-IN-CADENCE` line, and write a
`NEXT-CHECK-IN` line in its place. If your last check-in was STEP-30 and your cadence was 20,
that is `<!-- NEXT-CHECK-IN: STEP-50 -->`. If you never set a cadence, 20 STEPs past your last
check-in reproduces the old default. If you have never run one, pick any STEP number ahead of you,
or a date. New projects are seeded `STEP-20` from `templates/overview-template.md`.

**If you skip it, nothing breaks.** A missing or unrecognised value reads as *none scheduled*, and
`./doctor.sh status` says so and asks you to set one — on every run, until you do. A leftover
`CHECK-IN-CADENCE` line is inert: nothing reads it, and nothing reports it as an error.

**Two things you no longer have to do.** Past Check-in STEP rows need no particular Title — nothing
counts them, so nothing has to be renamed. (`Check-in` stays in the documents as a roadmap
convention; it is simply not a contract any more.) And the cadence is no longer a number your
documents have to keep in step with a setting, so the passages that named it now describe the
scheduled line instead — all of them in the process-docs group at step 1 of the fast path.
`scripts/check.sh` loses the check that validated the setting. That was **check 10 in 1.7**, and
check 10 in the release you are pulling is the new repo-registry pass instead — so if anything of
yours reads the doctor's output by check number, that number now means something else.

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
  `runbooks/README.md`, `METHOD.md` §3, §5, §7 and §10, `runbooks/collaboration.md` §6, §8
  and §9, `prompts/README.md`, `registries/README.md`, `registries/repos.yml`'s header,
  `AGENTS.md`, `runbooks/check-in.md`, `runbooks/dependency-supply-chain.md`,
  `runbooks/incident-postmortem.md`, and the templates `repo-readme-template.md`,
  `substep-prompt-template.md`, `step-index-seed.md`, `planning-session.md` and
  `reports/check-in-report-template.md`): two new runbooks plus the edits that route to
  them —
  `METHOD.md` §7 gains the mono→multi special case (that STEP is
  branchless, and its number is reserved on trunk), `collaboration.md` §9 gains a mono path
  through solo→team including the warning not to run `scripts/setup-workspace.sh` in a mono clone,
  and `prompts/README.md`'s thin-STEP note now names two families rather than the check-in alone.
  `AGENTS.md`, `check-in.md`, `collaboration.md` §8 and the substep template stop describing a
  registry row and name the registration action; `check-in.md`,
  `dependency-supply-chain.md` and `incident-postmortem.md` carry the reachability wording; and the
  planning session decides whether a repo the architecture names already exists by looking for a
  repository rather than by reading a README.
  **Five templates travel with this group even though §2's buckets call templates future-only.**
  `templates/repo-readme-template.md` gained the `## Role in <project>` augment form, which is what
  `runbooks/register-repo.md` sends you to when a repo already has a README, so a 1.7 copy of it
  leaves the new runbook pointing at nothing. A 1.7 `substep-prompt-template.md` still sends an
  agent off to write a registry row by hand, and `step-index-seed.md` gains the `N/A` substep
  status note. `reports/check-in-report-template.md` gains the Deferred Coverage table the updated
  `check-in.md` tells you to fill in. `templates/planning-session.md` is the fifth, and it is the
  one that changes behavior — see below.
  Apply them as a coherent group; they reference each other. No split-specific check: the new `check.sh` registry pass looks only for a missing `location:` and for
  repos no recorded remote covers. The script change these docs pair with is the scheduled check-in
  in `status.sh` (item 6 above) — pulling it also makes a STEP row carrying an inline
  `<!-- … -->` note visible to the resolver again, where the note used to swallow the row. Nothing
  detects registry drift *after a split* — a row that still describes a
  folder that is now its own repo — which is accepted rather than overlooked.
- *Project state* (your existing `registries/repos.yml` rows and your repos): never auto-updated.
  `provenance:` is a new optional block recording that a repo was split out of another one — where
  it came from, and where the two histories part company. It is written **at** a split and only
  then, so existing rows do not gain it and a project that split before 1.8 does not backfill.

**How to bring a repo into a project is now written down.** `runbooks/register-repo.md` is the one
procedure for it — whether Throughstone creates the repo or takes on one that already exists — and
everything that changes the set of repositories your project has goes through it, the split
included. **Which README a repo gets is decided by what is in the repo, not by how the repo
arrived**: no README means one stamped from the template, an existing README keeps it and gains a
`## Role in <project>` section, and registration never adds a second. An adopted repo gets
`LICENSE-THROUGHSTONE` and never a project `LICENSE` — choosing a licence for code the method did
not write is not the method's to do. The per-posture licensing detail that used to sit in
`METHOD.md` §7 moved into the runbook, beside the step that performs it, so §7 no longer answers
"what `LICENSE` does this repo get".

**Pull `scripts/apply-project-license.sh` with that runbook.** The runbook calls it with a
`--notice-only` flag a 1.7 copy does not have.

**One rule change rides along, and it forces nothing on you today.** STEP-1 work takes the
`step-0001-architecture` branch in **every** repository it writes into — not only the docs hub,
`prompts/` and the mono root, but any repository that already existed and has since been brought
into the project. It matters from the moment you run a STEP that writes into an adopted repo; until
then there is nothing to change.

**Your process docs now point at that procedure, and three of them behave differently because of
it.** Everything that used to send an agent off to write a `registries/repos.yml` row by hand —
`AGENTS.md`, the substep prompt template, `runbooks/collaboration.md` §8 — names the registration
action instead. None of them describes a row any more, which is what keeps them correct as the
fields change. **`runbooks/check-in.md` also changes two of its own rules**: a Check-in STEP may
now make a small corrective code or test fix to clear a failure it found, where it used to write no
application code at all, and its mechanical pass now states what to do with each finding — a
`[FAIL]` gets fixed, a `[WARN]` gets a decision rather than a reflex fix. Three more things behave
differently:

- **Your next check-in sweeps repo READMEs by what each README says, rather than uniformly.**
  A README stamped from the template is reviewed whole, as it always was — Overview, Setup /
  Running / Testing, and any `ARCHITECTURE.md`. One carrying a `## Role in <project>` section is
  reviewed only down to the next `##`, leaving the rest of somebody else's file alone. One with
  neither marker is not edited at all, and gets one question instead: can someone standing in this
  repo still find their way back to the project?
  **The "do the setup steps still work from a clean checkout" check now survives only on a README
  we stamped** — on one carrying a `## Role in <project>` section, or with no marker at all, it is a
  judgement about somebody else's repository rather than about your connection to it. Two smaller shifts ride along: a registry row and its Architecture
  Overview entry now count as **one** thing that drifts, fixed by re-running the registration
  rather than by editing either side; and the licensing question is never re-asked per repo,
  because that posture lives in one project-wide file.
- **`runbooks/collaboration.md` §9 no longer stands up a remote for every repo.** Going solo to
  team, the create-a-remote-and-push-your-history step is now scoped to repos that have no
  remote yet. As it stood, following it literally would have created a second remote for a
  repository that already had one and pushed its history there. Recording a remote a repo
  already has is unchanged, and every repo that has one still gets its `remote:` field.
- **The planning session no longer decides a repo exists by reading its README.** Its
  repo-scaffolding step used to count a repo as already there only if it had a registry row
  **and** a README whose role one-liner and Overview were filled in — so a real repository with a
  thin README was judged absent and scaffolded over, writing a stack, CI, an `.env.example`, a
  `.gitignore` block and possibly a license into somebody's existing work. It now asks whether the
  repo is already registered, and if it is not, whether there is a repository at that location —
  a work-tree root, not a folder that looks finished. Asking the registry first also means a repo
  you have registered but **not cloned on this machine** is never re-created. Where no repository
  is found the step creates one as before, with one addition: if the path already holds files this
  project did not put there, it stops and asks rather than scaffolding over them. Where one is
  found, **no stack wiring, no CI,
  no `.env.example`, no `.gitignore` block and no project `LICENSE`** go into it, and it is
  registered instead — what does land there is the registration action's call. Creating and
  registering are both a STEP's
  work, as they always were; the session decides and outlines. Adopt the reworded step.
  Nothing of yours is rewritten, and a first run on a fresh project behaves exactly as it did in
  1.7.

**The rule for making a repo public is now written down, and there is nothing of yours to
change.** A repo goes public only on an explicit instruction from you that names that repo — a
license, a public sibling repo, a remote, or a project that calls itself open source is not that
instruction, and neither is silence. It reads the same whether Throughstone created the repo or
took on one that already existed. Where a repo is being stood up, create it **private** — widening is a separate decision, made deliberately later. The rule
lives in `METHOD.md` §7 and in the two templates that touch a repo as it is brought in,
`templates/planning-session.md` and `templates/repo-readme-template.md`; all three travel with
item 1's group above, so pull them together — the rule is only as good as the least-updated of
them — and there is no new step to take. **Nothing of yours changes with it**: nothing in your
project records a visibility decision, and no check tests for one. What
changes is that an agent working in your project finds the rule stated rather than having to
arrive at it. **One thing to check:** if you are not sure how a repo of yours came to be public,
this is a cheap moment to look — one glance at each repo's host page. 1.7 asked you to choose
visibility deliberately but never said what a public answer had to come from, and setting a repo
private again governs only what happens next: it retrieves nothing already cloned, cached, or
crawled.

**And the rule now reaches the two pages that are open when a remote gets created.** Stating it in
`METHOD.md` and the templates left out `runbooks/register-repo.md`, where a repository is brought
into a project, and `runbooks/check-in.md`, where the doctor reports a repo with no remote and
somebody acts on it. Both told you to push the repo somewhere and neither mentioned visibility.
All three now say a remote created for a repo that has none is created **private**. The doctor's
own fix line changes with them, and it stops conflating two situations: it reads
`registries/repos.yml` and not git, so a row with no `remote:` may mean the repo has one nobody
recorded — write it in — or that it has none — create it, private, or accept the risk deliberately.
All three files are in item 1's group above; **nothing else of yours changes**, and the registry's
`remote:` field is still never created and never repointed by registration, which records what is
already there.

**Three read-only sweeps stop over-promising.** The check-in's full test run, the dependency
audit and the incident runbook's hunt for similar issues each asked for "all repos"; they now ask
for every repo you can reach, and for the ones you can't to be named. What that guards against is
not missing a repo — it is a partial sweep that reads as a clean one. If every repo your project
has is on your machine, nothing about these three changes for you.

**What the doctor says about that file after you pull, and the flag that makes it look.**
`scripts/check.sh` reads `registries/repos.yml` for the first time in this release — but only when
you pass the new **`--check-in`** flag. A plain `./doctor.sh check` prints the section as
`skipped`, and CI never passes the flag, so nothing about the registry can fail a build on a push.
`runbooks/check-in.md` is what passes it: the check-in's mechanical pass now runs
`Code/<project>-docs/scripts/check.sh --check-in` from the workspace root. It checks two things
and only two:

- **A row with no `location:` fails the run.** Nothing can find that repo without one. Ask whoever
  knows where it lives and write the path in; do not guess one. **So does a row the doctor cannot
  read** — one that does not start with its `- name:` line, which leaves its fields on the row
  above; the doctor counts the list's entries to know it read them all. These are the only registry
  findings that can turn a check-in red, and a 1.7 registry cannot produce either unless a row was
  hand-edited.
- **A repo that no recorded remote covers is a warning**, named row by row: as far as the project
  knows, that repo's work lives on exactly one laptop. **Most 1.7 projects will see this at their
  first check-in after upgrading**, because a 1.7 registry ships two rows with no `remote:`, and
  `init.sh` fills one in only if your bootstrap actually created remotes. Record the URL if the repo
  already has a remote; if it has none, create one — **private**, widening being a separate decision
  made deliberately later — then push and record the URL, because the field records that a remote
  exists and does not prove anything was pushed to it. Or decide that
  local-only is still fine. **Nothing records that decision**, so the warning comes back every
  check-in. That is the design, not a defect: a `[WARN]` is for deciding about, not for reflexively
  clearing, while a `[FAIL]` gets fixed.

**Mono-repo-for-now projects: add a row for the workspace root, or that warning will be wrong.**
A 1.7 registry lists the docs hub and `prompts/` — both folders inside your one repository — and has
no row for the repository itself. The check treats a row whose `location` is `.` as the thing that
contains the others, so without it you are told all your repos are unbacked-up even when the one
real repo is pushed. Add it by hand. **Put nothing after any value**: these readers treat a `#` on
a value line as part of the value rather than as a comment. **Quote values with double quotes, as
below, or not at all**: they read a single quote as part of the value too. Drop the `remote:` line
if the repo has no remote yet:

```yaml
  - name: "<your-project>"
    location: "."
    type: mono
    added_as: created
    remote: "git@example.com:TEAM/<your-project>.git"
    description: "The workspace root: the one repository this project lives in until it is split."
```

New projects get this row from `init.sh`; `init.sh` runs once, so nothing adds it to a project that
already exists. Multi-repo projects have nothing to add.

**One new registry field, and nothing to do about it.** Rows may carry `added_as:`
(`created` | `adopted`), recording how the repo arrived. **No script reads it** — it is a stamp for
a human. Existing rows do not need it and are not rewritten; it is written when a repo is
registered from here on.


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

**Multi-repo only: a teammate whose workspace setup died part-way can now finish it.** (In a
mono-repo-for-now project, `collaboration.md` §9 says not to run this script at all — no row in
that registry is a repo to clone.) If someone ran
`Code/<project>-docs/scripts/setup-workspace.sh` and it stopped with a `git clone` error, leaving the
workspace root with no `AGENTS.md`, no `CLAUDE.md` and no `doctor.sh`, that was one failing clone
taking the whole run down with it. **Pull 1.8 into the docs hub and run the script again.** Nothing
needs undoing first: repos already cloned are left alone, the pointer files are rewritten every run,
and the run now finishes whatever happens to the clones. Its closing line says how many repos did not
arrive, so fix the `remote:` or `location:` in `registries/repos.yml` — or clone that one repo by
hand — and re-run to pick it up.

**Multi-repo only: the same script now clones nothing from a registry with a row it cannot read.**
It reads a row only from its `- name:` line. A row that starts any other way used to be passed over
without a word, its fields landing on the row above — so one repo never arrived, or another repo's
remote was cloned into its folder. The run now says so instead; fix that row and run it again. A 1.7
registry cannot produce this unless a row was hand-edited.

**A `location:` that points outside the workspace root stops working, and 1.7 told you it was
allowed.** 1.7's `registries/repos.yml` header said a `location:` MAY point outside the `Code/*`
shell — an absolute path, or any other arbitrary path — and `METHOD.md` §7 documented registering a
repo in place that way. `scripts/setup-workspace.sh` used the value verbatim. **That is now a rejected shape.**

A `location:` must be **a path relative to the workspace root, identical on every machine; it never
begins with `/` or `~`, and no segment of it is `..`.** Anything else is skipped rather than cloned
into, so `setup-workspace.sh` will no longer fetch that repo for anyone; it says so when the row
carries a `remote:` there was something to fetch from. On the one machine where the path does
resolve, the run now reports the bad shape instead of reporting the repo as already present.

**Check every row in your registry, and fix the ones that break the shape.** Either move the repo to
a path inside the workspace and update the row, or — if it genuinely cannot move — **leave the repo
exactly where it is and put a symlink at its workspace-relative location pointing at the real
checkout**, then register the symlink's path. The repo's contents are never touched either way. The
symlink is followed, so the checkout behind it is found and left alone, and every other contributor
clones the real thing into that path.

Two shapes that used to look harmless are worth knowing about while you are in there: the value is
passed literally, with **no shell expansion and no YAML interpretation**, so `~/lib` and `$HOME/lib`
are directory names rather than paths to a home directory. `~/lib` used to clone *successfully* into
a literal `~` folder under the workspace root and report it as an ordinary clone; it is now skipped.
`$HOME/lib` still makes a literal `$HOME` directory, and no guard can tell that from a directory
somebody meant to call that.

**And check that nothing follows a `- name:`, `location:` or `remote:` value.** The scripts that
read the registry take a `#` on those lines as part of the value, not as a comment. 1.7's
commented-out example row carried `# team mode: setup-workspace.sh clones this` after its
`remote:`, so a row copied from it records a clone URL that does not exist. `setup-workspace.sh`
reports that repo as one that did not arrive, on every machine except the one that already has the
checkout, where it says `exists` and nothing more; and the check-in counts the value as a recorded
remote. Move the note to a line of its own, or delete it.

**Templates and guidance text, with nothing to undo.** Three edits to
`templates/architecture-sessions/*.md`, one to `METHOD.md` §3, one to
`templates/planning-session.md`, and four documentation fixes. None
of them rewrites anything you already produced; they affect work you do after pulling them.

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
- **The Cross-Cutting Review reads the code when the docs disagree.** Session 1.14's consistency
  check now says that where code exists, a contradiction between two architecture docs is settled
  by reading the code rather than by re-deciding it, and that the two outcomes leaving a real gap
  behind — two patterns genuinely both in the code, or a doc stating an intent the code
  contradicts — each file a `registries/risks.yml` row, so every check-in re-reads them. The
  foreclosure check keeps its walk and gains a forward question about the roadmap. Decision
  coverage still asks for the ADRs that are missing, and now says a decision made *during* the
  review is an ordinary ADR while a pre-method choice nobody can explain is recorded in the
  architecture doc rather than given an invented rationale. `METHOD.md` §3 moves with it:
  architecture docs are the single source of truth for the **intended** design, and where a doc
  and the code disagree the code is authoritative for what the system does. Nothing to undo — this
  changes reviews you run from now on. If you have **already run session 1.14** on a project that
  has code, the three rules are worth one pass at your next check-in, which reconciles the docs
  against the code anyway.
- **The planning session asks whether you are building on somebody else's code.** Before it
  proposes the STEP list it puts one question to you — is any of the code this phase builds on
  code this project did not write, that no check-in has yet run over? — and if you say yes, it
  puts a check-in titled `Check-in: baseline` at the front of the phase, running
  `runbooks/check-in.md` end to end, both substeps. That is the **first** point in the method
  where a codebase you took on gets its tests run: the architecture STEP writes documents and
  runs nothing, so until then nothing had. The runbook is unchanged. Nothing to undo — this
  changes planning sessions you run from now on. **On an existing project**, answer the question
  the way it is written: if a check-in has already swept that code, say so and no baseline is
  added; if it genuinely has never been run, you get one. Either way it is the same runbook, so a
  deliberate check-in at your next sensible breakpoint does the same work if you would rather not
  wait for the next planning run.
- **Lifting a document into `architecture/` now names all three header fields.** `inputs/README.md`
  told you to add the `Version` / `Status` header and omitted the **Version Log**, which `check.sh`
  check 4 also requires of every numbered architecture doc — so a lifted spec could fail the check
  that guards it. Pull the updated `inputs/README.md`. If you have **already lifted** a document,
  run `./doctor.sh check`: check 4 names any doc missing a field.
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

Pull `templates/architecture-sessions/*.md`, `METHOD.md` §3, §4 and §6, `inputs/README.md`,
`templates/architecture-doc-template.md`, `templates/planning-session.md`, and
`runbooks/check-in.md` as a group. Nothing else in this group is affected: these files
change no script behavior and touch no project state.


**Three generated docs need pulling, and that is the whole action.** The docs hub's own
`README.md` and §2's file-bucket table above were each written when Throughstone only ever
*created* a repo; the method can also take on one that already exists, where it writes at most two
files — that repo's README and the `LICENSE-THROUGHSTONE` notice, never CI and never a project
licence. `ONBOARDING.md` is the third, for a different reason: it still described
`setup-workspace.sh` cloning before it writes the root pointer files, which is the order this
release reversed, and it gains a line declaring that its own paths are relative to the workspace
root. `AGENTS.md` described that same old order and is corrected too — it is already in the
process-docs group above, so pulling that group picks it up. Review the three like the other
process docs; nothing of yours is rewritten.

**One thing this guide does not do for you.** `adr/README.md` is *Project state* under §2 —
never auto-updated — so the ADR duplicate-number scan fixed in this release stays broken in your
copy until you carry the fix across by hand. Open your `adr/README.md`, find the scan command, and
make it name the file from the workspace root the way the scaffold's copy now does.

### 1.7 migration

**Upgrading from 1.6? Start here.** This release rewrites no project files. Only two defaults
shift, and only once you pull the new tooling/templates: the doc-maturity ladder and the check-in
cadence. Fast path:

1. Pull the process docs + tooling as one review-required group (`METHOD.md`,
   `runbooks/check-in.md`, `templates/planning-session.md`, `scripts/status.sh`, `scripts/check.sh`).
2. Want the old check-in window (DUE 10 / OVERDUE 20)? Add `<!-- CHECK-IN-CADENCE: 15 -->` to
   `overview.md`; otherwise omit it to take the new default of 20 (DUE 15 / OVERDUE 25).
   **Superseded in 1.8** — the cadence setting is gone and `overview.md` records when the next
   check-in is due instead. Going straight to 1.8? Skip this step and follow the 1.8 section.
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

**Project-selectable check-in cadence.** *(Superseded in 1.8, which replaces the setting with a
recorded `NEXT-CHECK-IN` line — read the 1.8 section instead if you are upgrading past 1.7.)*

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
   rules in §8 and §10, then run `./doctor.sh check`.

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
2. Run the docs hub checks (`./doctor.sh check`).
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
