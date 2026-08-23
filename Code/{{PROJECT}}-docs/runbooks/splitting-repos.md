# Runbook — Splitting a Repository

> **How to run:** Two cases behind one procedure. Answer the three questions in **Before you
> start**, then go to your part — you don't pick the case, it falls out of the first answer.
> Tell your agent *"run the split"* and it follows this file.
> - **Part 1 — Splitting a code repo in two.** The ordinary one: a repo grew two things that
>   should ship separately. Any number of times.
> - **Part 2 — Converting mono-repo-for-now to multi-repo.** At most once per project, and only
>   if you started mono (`METHOD.md` §7). The workspace root stops being a repo.
>
> **Do the whole split on one machine, in one go.** It turns on local state no repo carries — the
> build directory, the files you carry across by hand, the mapping you wrote down — so a
> half-finished one does not hand off.
>
> Either way, when you're done: push every repo you touched, and tell your teammates.
>
> **Stop and get a go-ahead before continuing at each of these**, even where a default already
> answers the question. A split is rare and mostly hard to undo, so the extra exchanges are the
> cheapest part of it: before the first destructive command, with the mapping written out; at
> every file-list confirmation point, showing the list itself and never a summary; when you
> reconcile two ignore files into one, showing both and what you merged them into; before
> anything leaves your machine — creating a remote, pushing a trunk; and before anything on disk
> stops being easy to undo — pruning the origin, clearing what it left behind, swapping the
> workspace, retiring the old remote.
>
> Each one is marked **Stop** where it fires — in the mechanic, which runs in three pieces per
> repo, and at the steps below. Getting a go-ahead means ending your turn and waiting for a
> reply, not recording afterwards that you passed the point.
>
> **A split is a STEP**, like the check-in. Its PLAN is thin and points here; you don't author
> substep prompts for it — this runbook *is* the substeps (the same special case as the check-in,
> see `prompts/README.md`). *Substeps*, below, names the usual breakpoints.
>
> **Two special cases.** **Part 2 is branchless** — there is no `step-NNNN` branch, because the
> repos that branch would live in are the ones being created. Its STEP number is reserved
> *on trunk* at step 4 (`METHOD.md` §7). And **tracking a split as a STEP is the method's
> convention, not an obligation**: a project that would rather not track this one skips Part 2's
> steps 4 and 13 together and loses nothing else. Part 1 needs no equivalent — `prompts/` is
> untouched there, so the ordinary recipe in `prompts/README.md` applies unchanged.

## Why this runbook exists
"Splitting later is standard git" is not an answer you can act on. The published standard
procedure — GitHub's, Atlassian's — makes the extracted repo **new**, with its history rewritten
by `git filter-repo`: a tool that never ships with git, needs Python on every install route, and
behaves differently version to version, so the method cannot require you to have it. A rewrite
also truncates history at every historical path you forget to name, silently.

So this runbook does something else, and it is deliberately **not** the recipe you will find
elsewhere: it clones the whole repo and **deletes forward**. Nothing is rewritten. Both sides keep
the full history; the shared commits are the same objects with the same SHAs in both repos, so
`git blame`, `git log --follow` and `git bisect` work in the new repo on day one, `git merge-base`
resolves across the split, and anything recorded against a commit — a `reviewed_commit:` in
`registries/security-reviews.yml`, a SHA in a report — keeps resolving.

The cost, stated plainly: **every new repo inherits every blob the origin ever committed**,
including files deleted long ago. If a secret was ever committed, the split copies it into a
second repo. The third question below is where that gets decided, and the appendix is where it
gets handled.

## Substeps

There is no fixed number of them, because the shape of a split follows the shape of your repos.
The usual breakpoints:

- *Part 1, typically three:* **N.1** pre-flight, extract and stand the new repo up (steps 1–5) ·
  **N.2** prune and repoint (steps 6–8) · **N.3** verify (step 9).
- *Part 2, typically four:* **N.1** pre-flight and backup (steps 1–3) · **N.2** build the new repos
  beside (steps 5–7) · **N.3** assemble and verify the workspace (steps 8–10) · **N.4** swap and
  retire (steps 11–12). Steps 4 and 13 are the STEP's own bookkeeping rather than work inside it,
  which is also why they are the pair a project skips together.

A split that extracts several repos at once, or that stops at a boundary these don't anticipate,
names its own. The point of naming them is that the index should show where a half-finished split
stopped, not that every split has the same joints.

## Before you start — three questions

**1. What is the split — which folders end up in which repo?** There is no default; this is the
whole input, and everything else is derived from it. Before answering, **list the units** so
nothing invisible gets left behind:

```bash
git ls-files | cut -d/ -f1-2 | sort -u      # or: ls Code/, plus prompts/ and the docs hub
```

Every entry has to land in some repo's **keep-set** or be dropped on purpose. Work from this list,
not from `registries/repos.yml` — a folder that was never registered (a vendored SDK, an in-tree
tools directory, a repo somebody scaffolded and forgot to add) is invisible to every check in this
runbook and disappears at the split without a word.

If the answer is *"the workspace root stops being a repo"*, you are in **Part 2**. Otherwise
**Part 1**.

**2. Should you split at all?** *(Part 1 only — for Part 2 the layout decision was made at
`init.sh` time.) Default: proceed.* One exchange, and the two questions worth asking are: would
the two halves be **chatty** with each other, and would an ordinary change require **deploying
both together**? Either one means the boundary is in the wrong place. Splitting a repo is
expensive and hard to undo; deciding not to is a real answer.

**3. Does this history have a secrets or size problem?** *Default: no.* If no, skip the appendix
entirely — it is not mentioned again. Say yes if a credential was ever committed and you would
rather it did not propagate into a second repo, or if the history carries large binaries you do
not want to copy. Then go to the **appendix** *before* doing anything else: purging is a rewrite,
and it has to happen first.

## The mechanic

Both parts build every new repo the same way, in bash, one repo at a time. `<keep>` is that
repo's keep-set — the path or paths from question 1 that this repo is meant to be. `<scope>` is
what you would call that out loud (`billing`, `the docs hub`); it appears only in the two commit
messages, which every repo the split produces then carries permanently.

**It runs in three pieces, and the breaks between them are stops, not formatting.** Run a piece,
show what it printed, wait for a go-ahead, then run the next. They are between the blocks rather
than inside them because a stop written as a comment on a line you are about to execute is not a
stop — it runs, and the block reads as finished. A stop can outlast the shell you started in, and
these commands are destructive in the wrong directory, so **run block 1 from the origin repo** —
it resolves `<origin>` and `<new-repo>` against wherever you are standing — while blocks 2 and 3
re-enter the new repo themselves on their first line. Block 3 leaves you inside the repo you just
finished, which is not where the next repo's block 1 starts.

```bash
git clone --no-local <origin> <new-repo>      # --no-local is required for a local source
cd <new-repo>
git remote remove origin                      # the new repo must not point at the old one

for p in <keep>; do echo "$p: $(git ls-files -- "$p" | wc -l | tr -d ' ') file(s)"; done
```

**Stop.** Show the mapping — this repo, its keep-set, and that count, one line per path. Every
path has to be non-zero: a zero is a path that is mistyped or wrong-cased, or a clone taken from
somewhere other than the origin, and the delete below removes everything the keep-set did not
match. Nothing has been deleted yet.

```bash
cd <new-repo>
git rm -r -q -- . ':!<keep>' ':!.gitignore'   # forward-delete the complement; nothing is rewritten
test -n "$(git ls-files -- <keep>)" || { echo "<keep> matched nothing — check the path"; exit 1; }
git commit -m "Split: this repo now holds <scope>"
```

**Stop if the kept directory has its own `.gitignore`** — reconcile it here, before the move, and
show both files and the one you merged them into before you stage it (see below). Nothing further
down reads that file, so a rule dropped here reaches the finished repo unremarked. No nested
ignore file, no stop: carry straight on.

```bash
cd <new-repo>
# The un-nest below applies only when <keep> is a SINGLE directory. With a scattered keep-set
# (two or more paths) skip the next three lines: those paths stay where they are.
( set -e; shopt -s dotglob nullglob; for e in <keep>/*; do git mv "$e" .; done )
test -z "$(git ls-files -- <keep>)" || { echo "un-nest incomplete — reconcile and re-run"; exit 1; }
git commit -m "Move <scope> to the repo root"
find . -mindepth 1 -type d -empty -not -path './.git/*' -delete

git ls-files
```

**Stop.** Show that list — it is the repo you just made, and nothing else will tell you whether it
is the right one. Then start the next repo.

**`.gitignore` is exempt from the delete, and that exemption is load-bearing.** Without
`':!.gitignore'` the new repo inherits no ignore file, and nothing left inside it can regenerate
one — the only thing that writes a `.gitignore` is `init.sh`, which the new repo doesn't have
either way. The measured result is a repo that tracks `.env`. After the un-nest, confirm the
exemption worked: `git check-ignore -v .env` should exit 0.

**If the kept directory has its own `.gitignore`, reconcile before the move.** Two files exist at
that moment: the origin's, which the exemption above left at the root, and the kept directory's,
still nested — and the move will stop on the collision. Read both, reconcile them into one file at
the repo root, `git rm` the nested one, and `git add` the reconciled one — nothing further down
stages that edit for you. *Default: the union of the two.* Re-anchor any rule written against the
old path (`/Code/<name>/dist/` becomes `/dist/`); it matches nothing after the move. In Part 2 this
fires for every code folder, and never for `prompts/` or the docs hub, which have no ignore file of
their own. In Part 1 it usually does not fire at all, because the extracted directory is a
subdirectory of a code repo — the dead path-anchored rules it would have caught are what step 7's
repointing grep is for instead.

**The two checks do different jobs, and both are needed.**

- **The guard, before the move**, catches a keep-set that matched nothing. If the path is
  mistyped — or just the wrong case, since macOS treats `code/` and `Code/` as the same folder
  and git's pathspecs do not — the forward delete removes *everything*, the move loop iterates
  zero times, and the check after it passes vacuously, because "the old path is empty" is also
  true when it never held anything. The only signal is `nothing to commit, working tree clean`,
  which reads like success. The guard fires at the one moment the mistake is still free.
- **With more than one keep path, the per-path count in the first block is the check** —
  `git ls-files -- <path>` non-empty for *each*, not for the set. A set-wide check passes on the
  one path that matched while the mistyped one is deleted with no signal. And note what a
  scattered keep-set does not get: the un-nest applies only when the kept set is a single
  directory, so a scattered split has no post-condition either. The per-path guard is the only
  mechanical check it has.
- **The post-condition, after the move**, catches a half-finished un-nest. Do not try to replace
  it with a check on the loop's exit status. The `set -e` is inside the subshell, so a failed
  `git mv` exits the subshell and the next line runs anyway — `git commit` then succeeds, commits
  whatever prefix of entries the loop managed to move, and leaves `git status` clean. And the
  obvious fix is worse: writing `( set -e; … ) || exit 1` **disables** errexit inside the
  subshell, because a compound command on the left of `||` is exempt from it, so the loop runs
  past the failure and moves *more* files, not fewer. `git ls-files -- <keep>` reads the index, so
  it is true whatever went wrong.

**Why the confirmation points print a file list.** The forward delete and the un-nest are the two
steps that can succeed while producing the wrong repo, and their exit status will not tell you.
The list is what shows it. Do not skip past it, do not replace it with a summary, and do not
carry on until the person running the split has seen it and said go.

**Reading a path across the un-nest.** The move is a rename, so plain `git log -- <path>` stops at
the un-nest commit; use `git log --follow -- <path>`. `git blame` crosses it without help.

**The origin's tags come across too.** The clone carries every tag, and in a new repo they point
at trees that are not this repo — `git describe` will report `v1.0-3-g…` against a release of the
thing you split away from. `git push` does not send them, so they stay local until someone asks
for them. Keep, retag or delete is your call: nothing in the method reads tags.

**The origin side needs none of this.** Its paths are already correct, so it gets no clone, no
exemption and no un-nest — just a forward `git rm` of what left (Part 1 step 6). In Part 2 there
is no surviving origin; every unit gets the mechanic above.

## Part 1 — Splitting a code repo in two

The **origin repo** survives and keeps its identity, its remote and its history. The **extracted
repo** is new. The docs hub and `prompts/` do not move.

*Tracking this as a STEP?* Reserve the number, branch, and archive the PLAN exactly as
`prompts/README.md` says — `prompts/` is untouched by this split, so none of that timing is
special here, which is why it gets no steps of its own below.

> **Where abort gets expensive.** Up to step 6, abort is cheap: delete the new directory, and
> delete the extracted repo's remote if you already created it. Nothing else has been touched, and
> neither the origin nor the hub has been pushed. From step 6 on the origin has been pruned
> locally, so abort means deleting your local copies and re-cloning them from their remotes.
> **Save anything untracked or ignored first** — `.env`, `.secrets/`, in-flight work. Nothing
> carries it.

1. **Confirm the mapping and the boundary** (questions 1 and 2). Write down the origin repo, the
   path being extracted, and the new repo's name. **Stop here, before step 3 builds anything** —
   show that written-out mapping and your answer to question 2. Deciding not to split is one of
   the answers, and this is the step where it gets made.
2. **Pre-flight: the branches that won't survive.** Run `git branch -a`. A clone carries every
   commit and every tag, but only the default branch arrives as a real branch — the rest exist
   only as remote-tracking refs and die with `git remote remove origin`, silently. The origin repo
   survives, so nothing is lost there; the risk is in-flight work on the *extracted* files, which
   lands in a repo where those files no longer exist. Merge or close everything but trunk before
   starting, or accept the loss knowingly. **Commit or stash your working tree too** — the clone
   takes committed state, so an uncommitted edit never reaches the new repo.
3. **Extract.** Run the mechanic above with `<keep>` set to the path being extracted. When it
   prints `git ls-files`, read it: it should look like the repo you asked for, at the root, with
   nothing left nested.
4. **Make it a repo, not a folder.**
   - `scripts/apply-project-license.sh <new-repo-path>` from the docs hub.
   - A `README.md` stamped from `templates/repo-readme-template.md`, with its role one-liner and
     Overview actually filled in.
   - `templates/env-example.txt` copied in as `.env.example` if it needs one.
   - **Its build and test entry point.** The forward delete removed the origin's `Makefile`, CI
     config and test harness, so right now this repo has no way to build itself. Decide what it
     runs. If the extracted code also calls into code that stayed behind, decide that here too —
     the options are duplicate it, put it in a third shared repo, have one side own it and expose
     it as a service, or don't split at this boundary after all. There is no threshold that picks
     for you; the one thing every source agrees on is not to share domain logic.
   - **Commit all of it.** The stamping writes new, untracked files and the next step pushes.
5. **Give it a remote.** Create it **private** — widening is a separate decision, made deliberately
   later, and this repo now carries the origin's whole history. **Push trunk before you record the
   remote anywhere** (step 8 writes the registry row): that is the order `collaboration.md` §9
   already uses, and it is what stops the next person cloning an empty repo. **Stop before this
   step runs** — creating the remote and pushing trunk are the first two things that leave your
   machine.
6. **Prune the origin.** `git rm -r -q -- <extracted-path>` and commit. Then **`ls -a
   <extracted-path>`** — do not look for dirtiness. `git rm` removes only tracked files, and what
   stays behind is everything the repo was told to *ignore*: build output, vendored files,
   snapshots, `.env`. Ignored files never show as dirty; they do not show at all. Clear what is
   left by hand — but first move anything that belongs to the **extracted** repo, its `.env` and
   `.secrets/`, over to it: the clone took committed state, so what is sitting here is the only
   copy. Two reasons clearing the rest is not just tidiness: stale build output where the source
   used to be can keep the origin's tests passing against code the repo no longer contains, and
   step 7's `git grep` searches tracked files only, so it will not see it either. **Stop on the
   `ls -a` output, before deleting any of it** — the `git rm` above is recoverable from history
   and this is not: no remote, no mirror and no clone holds these files.
7. **Repoint everything that knew the old path.** `git grep -n -F "<old path>"` in the origin, in
   the extracted repo, **and in the docs hub** — including each `.gitignore`, where a rule anchored
   at the old path is now dead. Every hit is either a repoint or a mention of history you keep on
   purpose. **This step is not optional and is the easiest one to skip:** the hub's link checker
   resolves link targets into the code repos, so a *correct* split makes hub links dangle —
   `scripts/links.sh` fails on a finished split and passes on an unfinished one. Step 7 is what
   makes step 9 satisfiable.
8. **Register it.** Add the new repo's row to `registries/repos.yml` with its `provenance:` block:
   the repo it came from, today's date, and the last commit the two repos share (the origin's tip
   before the prune — it resolves in both). Your-row-only, per `collaboration.md` §5.
9. **Verify.**
   - Both repos **build and test**.
   - `git status` is clean in each, and each local trunk matches its remote — that is the check
     that what you can see is what everyone else receives.
   - The step-7 grep now returns only the historical mentions you decided to keep.
   - `git log --follow` and `git blame` resolve across the un-nest in the extracted repo, and the
     pre-split commit exists in both.
   - `scripts/links.sh` is clean.

## Part 2 — Converting mono-repo-for-now to multi-repo

The workspace root stops being a repository. `prompts/`, the docs hub and each code folder become
repos of their own. This happens at most once per project.

> **You build the new workspace beside the old one and swap at the end.** Everything up to step 11
> happens in `../<project>-split/`; the live workspace is never touched, so abort is deleting that
> directory. Do not start by deleting or rewriting anything you have.

1. **Confirm the mapping** (question 1), and decide **where each root file goes**. Derive the list;
   don't work from memory:

   ```bash
   git ls-files -- . ':!Code/' ':!prompts/'    # everything tracked that no keep-set claims
   ```

   Nine entries on a stock mono root. *Default disposition:* the licence files are stamped into
   each new repo by `scripts/apply-project-license.sh` (step 6); `CLAUDE.md`, `AGENTS.md` and
   `doctor.sh` change kind at this split — they stop being committed files and become per-machine
   pointers regenerated by `scripts/setup-workspace.sh` (step 8); and `init.sh` has done its job
   and is dropped. Anything your project added to the root is yours to place.
2. **Pre-flight.**
   - **What git won't carry.** The swap replaces the workspace, so anything untracked or ignored
     has to be carried across on purpose. Derive both lists; never hand-write them:

     ```bash
     git status --porcelain --ignored
     git ls-files --others --exclude-standard
     ```

     *Default: carry everything listed.* This is where each code folder's own `.env` and
     `.secrets/` show up, which is exactly what a from-memory list misses. Note that a directory
     whose entire contents are ignored appears as a **single entry** and is not descended into —
     carry the whole directory.
   - **Branch state.** `git branch -a`. Only trunk survives a clone as a real branch; the rest die
     with `git remote remove origin`, silently. Here the root repo is being *replaced*, so a stray
     branch is stranded with nowhere to land. Merge or close everything but trunk first, or accept
     the loss knowingly. **Commit your working tree too** — the clones at step 5 take committed
     state, so an uncommitted edit reaches no new repo and nothing flags it. Stashing is not an
     alternative here: a stash lives in the repo you are about to replace, so pop it and commit
     before step 5.
   - **Write the mono repo's `origin` URL down now.** After the swap it exists nowhere on disk. Its
     durable home is `archive_remote:` in the registry at step 7; until then a scratch note is fine.
   - **Decide what happens to the old remote** at the end (step 12): leave it, retire it, or delete
     it. *Default: retire it.*
   - **Stop here, before step 5 builds anything.** Show the mapping written out — every unit and
     the repo it becomes, every root file from step 1 and its disposition, and both lists above in
     full rather than counted. Everything after this is derived from that answer.
3. **Backup mirror.** `git clone --mirror --no-local . ../<project>-presplit.git`, and confirm it
   is readable (`git -C ../<project>-presplit.git log --oneline -1`). Every new repo will carry the
   full history anyway, so this is a spare copy rather than the home of the project's past — skip
   it if you'd rather not, though it costs nothing. It captures **tracked content only**; it is
   not a backup of step 2's lists.
4. **Reserve the STEP number** in `prompts/STEP-index.md` and **commit the reservation on trunk**
   — this STEP is the documented exception to branch-per-STEP (`METHOD.md` §7). Uncommitted, the
   clones in step 5 never see it and the reservation dies with the old workspace; committed, the
   row rides across inside the `prompts/` keep-set. **The PLAN itself is written at step 13**,
   after the swap — written now, every new repo's forward delete would remove it. *Skipping the
   STEP framing? Skip this step and step 13 together.*
5. **Build the new repos beside.** For each unit — `prompts/`, the docs hub, each code folder — run
   the mechanic into its place in the new workspace:

   ```bash
   git clone --no-local . ../<project>-split/prompts        # <keep> = prompts
   git clone --no-local . ../<project>-split/Code/<name>    # <keep> = Code/<name>
   ```

   Reconcile the ignore file, un-nest, and read the file list each time. The reconcile fires for
   every code folder: the file the clone left at the root is the *workspace* root's, which carries
   none of that code repo's build ignores, and the folder's own is still nested.
6. **Stamp each new repo, and commit it.** Run `scripts/apply-project-license.sh` once per repo
   from the new hub, then **commit the result in that repo**. The script writes new, untracked
   files, step 7 pushes, and nothing else in this procedure commits them — skip this and a repo
   reaches its host with no `LICENSE`, no `LICENSE-THROUGHSTONE` and no `LICENSING.md` while your
   own copy on disk still shows all three.
7. **Remotes.** Create each **private** — every one of them now carries the whole mono repo's
   history, and widening any of them is a separate decision to make deliberately later, not a
   side effect of the split. Push trunk, then record `remote:` in
   `registries/repos.yml`. Every row in that file is now a split-out repo, so each also gets a
   `provenance:` block — naming the mono repo, today's date, the last commit they all share, and
   the `origin` URL you wrote down at step 2 as `archive_remote:`. **That commit has to exist on
   the archive too** — if the mono trunk you cloned at step 5 was ahead of its remote, push it
   there before you record these, because step 12 makes that host read-only. **Delete the
   mono-repo-for-now note** above the rows; it stops being true the moment this step runs.
   **Push the hub last**, after its registry commit, or none of these rows reaches a teammate.
   **Stop before the first create and push** — this is where the whole mono history leaves your
   machine, once per repo, and where private-or-not stops being a local decision.
8. **Root pointers.** Run `scripts/setup-workspace.sh` from the new hub, in the build directory.
   The build directory is assembled purely from clones, so it has no root `CLAUDE.md`, `AGENTS.md`
   or `doctor.sh` until this runs — and nothing would ever flag their absence.
9. **Carry the local state** chosen at step 2 — **plus `Upcoming Prompts/` and its contents, by
   name.** Its `.gitkeep` is tracked, so the folder is on neither of step 2's lists, and every new
   repo's forward delete removed it: no clone carries it. If it is empty, create it anyway — it is
   where the project's next PLAN gets written, and nothing else recreates it.
10. **Verify the build directory before you swap.**
    - Each new repo: `git status` showing nothing but that repo's entries from step 2's
      `git ls-files --others --exclude-standard` list, re-anchored to its new root; local trunk
      matching its remote; `git check-ignore -v .env` exiting 0; and nothing left under the path
      it was moved out of. Anything from step 2's *ignored* list showing up as untracked — a
      `node_modules/`, a `dist/` — means that repo's ignore file did not survive step 5's
      reconcile.
    - Each code repo **builds and tests**.
    - `scripts/check.sh` at **0 fail(s), 0 warning(s)** — warnings do not fail the run, so "green"
      is not the criterion.
    - `scripts/links.sh` clean.
    - A **real teammate clone**: a fresh empty directory, clone the docs hub into
      `Code/<project>-docs/` inside it, run `scripts/setup-workspace.sh` there, and confirm every
      registered repo actually arrives.
    - The pre-split commit resolves in every new repo.
11. **Swap.** **Stop before the rename** — show which directory becomes which. Then **rename** the
    old workspace aside — do not delete it — and move the build directory into its place. Abort is
    still just deleting the build directory. Delete the old workspace only after you have worked in
    the new one for a while: it is the only copy of anything step 2's lists missed, and no mirror
    holds untracked or ignored files.
12. **Retire the old remote**, per step 2's decision. *Default:* delete its contents in one tip
    commit, leaving a `README.md` that says the history is still there and how to reach it, then set
    the host's permissions to read-only. **Never delete refs**, and author that commit on a fresh
    clone of the host, not in your live workspace. Do this **after the swap is verified, never
    before** — a complete pushed copy stays on the host through the whole destructive window. That README needs
    one sentence for anyone else holding a clone: *start a fresh empty folder, clone the docs hub
    into `Code/<project>-docs/` inside it, and run `scripts/setup-workspace.sh` there — do not
    reuse your old project folder.* Re-onboarding in place leaves the new repos nested inside the
    retired one, and every check passes. **Stop before you push that commit** — show the README and
    the tree it leaves behind.
13. **Write the STEP's PLAN** and archive it into the new `prompts/` repo at
    `prompts/<phase>/step-NNNN/`, then mark the STEP done in `prompts/STEP-index.md`. Written now
    rather than at step 4, it never has to pass through a forward delete. *Skip this if you skipped
    step 4.*

## Appendix — purging history first

You are here because a credential or a large binary is in the history and you do not want it copied
into a second repo. This is the **purge** procedure, not an escape hatch from the default: it
rewrites history, so it happens *before* either part, on a mirror, once.

**Rotate the credential first.** A rewrite does not reach the clones your teammates already have,
or the copies on the host until it garbage-collects, or anything a CI log captured. Rotation is the
control; the rewrite is cleanup.

**Reconnaissance, before you rewrite anything.**

```bash
git clone --mirror --no-local <origin> ../purge-work.git   # work on a copy, never your only one
git -C ../purge-work.git filter-repo --analyze             # path + rename reports (needs the tool below)
git -C ../purge-work.git for-each-ref --format='%(objectname) %(refname)' > ../refs-before.txt
```

The `--analyze` reports are how you build the path list. **Neither tool follows renames.** History
truncates at every historical path you fail to name, silently — one reported case lost 119 of 144
commits of `--follow` history on a plain directory filter. If the file ever moved, every one of its
old paths has to be on the list.

**The tools.**
- **`git filter-repo`** is the one that handles a scattered set of paths, and the one you cannot
  assume anybody has: it never ships with git, every install route wants Python, and released
  versions differ enough in behavior that "it worked on my machine" is not evidence. Repeated runs
  are not reproducible — matching commit IDs across two runs happen by luck, not by design, as its
  own FAQ says.
- **`git subtree split`** ships with git and *is* deterministic: the same history splits to the
  same commit IDs every time. It is also single-prefix, single-branch, and exports no tags — and
  it **silently accepts only the last `-P`**. `-P src/api -P src/billing` exits 0, warns about
  nothing, and gives you only the billing files.

**Afterwards, diff the ref graph.** A branch whose commits all touched purged paths is not deleted
— it is remapped onto some other commit's SHA, and the tool reports no problems.

```bash
git -C ../purge-work.git for-each-ref --format='%(objectname) %(refname)' > ../refs-after.txt
diff ../refs-before.txt ../refs-after.txt
```

Two refs that now point at the same object collapsed. Decide what each one should be before you
push anything.

**What a purge costs you**, so nobody is surprised: every SHA changes, so every commit reference
recorded anywhere — `reviewed_commit:` in `registries/security-reviews.yml`, SHAs in reports and
ADRs, links in issues — stops resolving, and everyone re-clones. That is the trade for not carrying
the blob.

**If the motive is purely size**, there is a cheaper answer that rewrites nothing: let one new repo
inherit the origin's identity outright rather than cloning it. Move the `.git` directory into the
folder that is becoming a repo, then inside it `git rm -r --cached .`, `git add -A`, and commit. It
comes out with the complete un-rewritten history and `--follow` and `blame` resolving through the
path change — but only one repo can inherit it, and the workspace root stops being a repo the
moment you move `.git`, so this only makes sense as part of Part 2. **Do it last**, after every
other unit has been cloned at step 5, not here before Part 2 starts: the move drops those units
from HEAD, so their forward delete keeps nothing and the guard fires on a path you typed
correctly. Then **move the inheriting folder into the build directory** with the rest — step 11
moves that directory into place and would otherwise strand this repo in the workspace you renamed
aside. Its ignored files travel with it untouched, so step 9 has nothing to carry for it. And
be clear what it buys — one copy of the object graph, not the blob. Every other unit is still a
clone and still carries it.

**This replaces the clone and the forward delete, not the rest of the mechanic.** `origin` still
points at the mono repo, so `git remote set-url` it to this repo's own remote before step 7 —
otherwise "push trunk" pushes this tree over the mono repo's, and nothing errors. The root
`.gitignore` is not here to be exempted: copy it in and reconcile it with the folder's own, as
step 5 does. And `git add -A` commits every untracked file in the folder, where a clone would
have left them untracked — so end with `git ls-files` and stop on it, like every other repo.
