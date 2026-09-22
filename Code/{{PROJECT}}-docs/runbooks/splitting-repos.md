# Runbook — Splitting a Repository

> **How to run:** Two cases behind one procedure. Answer the three questions in **Before you
> start**, then go to your case — you don't pick which, it falls out of the first answer, and a
> mono-repo-for-now project that wants one repo out runs Case 2 first and then Case 1.
> Tell your agent *"run the split"* and it follows this file.
> - **Case 1 — Splitting a code repo in two.** The ordinary one: a repo grew two things that
>   should ship separately. Any number of times.
> - **Case 2 — Converting mono-repo-for-now to multi-repo.** At most once per project, and only
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
> stops being easy to undo — clearing what the prune left behind, swapping the workspace, retiring
> the old remote.
>
> Each one is marked **Stop** where it fires — in the mechanic, which runs in three pieces per
> repo, and at the steps below. Getting a go-ahead means ending your turn and waiting for a
> reply, not recording afterwards that you passed the point.
>
> **A split is a STEP**, like the check-in. Its PLAN is thin and points here; you don't author
> substep prompts for it — this runbook *is* the substeps (the same special case as the check-in,
> see `prompts/README.md`). *Substeps*, below, names the usual breakpoints.
>
> **Two exceptions.** **Case 2 is branchless** — there is no `step-NNNN` branch, because the
> repos that branch would live in are the ones being created. Its STEP number is reserved
> *on trunk* at step 4 (`METHOD.md` §7). And **tracking a split as a STEP is the method's
> convention, not an obligation**: a project that would rather not track this one skips Case 2's
> steps 4 and 13 together and loses nothing else. Case 1 needs no equivalent — `prompts/` is
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
resolves across the split once one repo fetches the other, and anything recorded against a commit —
a `reviewed_commit:` in `registries/security-reviews.yml`, a SHA in a report — keeps resolving.

The cost, stated plainly: **every new repo inherits every blob the origin ever committed**,
including files deleted long ago. If a secret was ever committed, the split copies it into a
second repo. The third question below is where that gets decided, and the appendix is where it
gets handled.

## What this runbook decides — and what you decide

Three different things happen here, and two of them look like the same kind of decision without
being one.

- **It decides the method's own artifacts**, and they are the minority of what happens here. Where
  `prompts/` and the docs hub end up, what the registry row and its `provenance:` block say, which
  licensing artifacts a new repo carries, what its README gains — those pieces exist because the
  method put them there, so the rules for them are this file's to state.
- **It drives plain git over your repositories, and the Stops are where you stand in front of it.**
  The clone, the forward delete, the prune, the swap and the retirement all run against code this
  runbook did not write and cannot check; the opening block lists the points it will not pass
  without a go-ahead. That is also why the confirmation points print a file list and wait rather
  than summarising: the mechanic can succeed and still produce the wrong repo, and somebody reading
  that list is the only thing between the two.
- **It decides nothing about how your code divides.** Which folders belong together is question 1
  below; whether the boundary is in the right place at all is question 2; what to do about code
  both sides call is Case 1 step 4 — three answers this file asks you for and derives everything
  else from. Nothing in it reads an import, a call graph or a build file; the only thing that reads
  the contents of your code at all is Case 1 step 7's literal `git grep` for the old path, which is
  why it cannot see a package reference that carries no path.

So where the two things you want apart are interleaved, untangling them is ordinary code work, and
it belongs on a STEP of its own, committed before the split runs. Signalling that you are at that
boundary is the method's part; doing it is yours. This runbook starts from your answer — it does
not go looking for one.

## Substeps

There is no fixed number of them, because the shape of a split follows the shape of your repos.
The usual breakpoints:

- *Case 1, typically three:* **N.1** pre-flight, extract and stand the new repo up (steps 1–5) ·
  **N.2** prune and repoint (steps 6–8) · **N.3** verify (step 9).
- *Case 2, typically four:* **N.1** pre-flight and backup (steps 1–3) · **N.2** build the new repos
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

If the answer is *"the workspace root stops being a repo"*, you are in **Case 2**. Otherwise
**Case 1**.

**Case 1 assumes the workspace root is not a repo.** In mono-repo-for-now it is, so extracting a
folder there leaves the new repo *nested inside* the origin — the root reports it as an untracked
directory, and step 9's `git status` check fails on it. It also strands the repo you just made:
a mono project's contributors clone the one root repository and are told not to run
`Code/<project>-docs/scripts/setup-workspace.sh` — run in a mono clone it overwrites the committed
root pointers with per-machine ones asserting the root is not a repo (`collaboration.md` §9) — so
nothing on the mono onboarding path would ever bring your new repo onto a teammate's machine.
**Run Case 2 first**, then Case 1 as often as you like on the repos it leaves you.

**2. Should you split at all?** *(Case 1 only — for Case 2 the layout decision was made at
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

Both cases build every new repo the same way, in bash, one repo at a time. `<keep>` is that
repo's keep-set — the path or paths from question 1 that this repo is meant to be. `<scope>` is
what you would call that out loud (`billing`, `the docs hub`); it appears only in the two commit
messages, which every repo the split produces then carries permanently.

**It runs in three pieces, and the breaks between them are stops, not formatting.** Run a piece,
show what it printed, wait for a go-ahead, then run the next. They are between the blocks rather
than inside them because a stop written as a comment on a line you are about to execute is not a
stop — it runs, and the block reads as finished. A stop can outlast the shell you started in, and
these commands are destructive in the wrong directory, so **run block 1 from the workspace root**
— it resolves `<origin>` and `<new-repo>` against wherever you are standing, and both are written
relative to that root. **Substitute `<new-repo>` as an absolute path**, so that blocks 2 and 3
re-enter the new repo themselves on their first line: a relative one resolves only from where
block 1 ran, and if your shell is anywhere else that `cd` fails and the forward delete below runs
against whatever repo you are standing in. Block 3 leaves you inside the repo you just finished,
which is not where the next repo's block 1 starts.

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
# With a scattered keep-set, <keep> substitutes here as one ':!<path>' per keep path. ':!a b' is a
# single pathspec that matches nothing, so the delete removes everything and the guard blames a
# path the count in block 1 just certified.
git rm -r -q -- . ':!<keep>' ':!.gitignore'   # forward-delete the complement; nothing is rewritten
test -n "$(git ls-files -- <keep>)" || { echo "<keep> matched nothing — check the path"; exit 1; }
git commit -m "Split: this repo now holds <scope>"
```

**Stop if the kept directory has its own `.gitignore`** — reconcile it here, before the move, and
show both files and the one you merged them into before you stage it (see below). Both files in
full every time, including at the second and third repo where the root one looks unchanged from
the last: *"same as before"* is the reviewer taking it on trust. Nothing further down reads that
file, so a rule dropped here reaches the finished repo unremarked. No nested ignore file, no stop:
carry straight on.

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
is the right one. Paste it whole however long it runs: a list with entries elided, or collapsed
into brace expansion, is a summary. Then start the next repo.

**`.gitignore` is exempt from the delete, and that exemption is load-bearing.** Without
`':!.gitignore'` the new repo inherits no ignore file, and nothing left inside it can regenerate
one — the only thing that writes a `.gitignore` is `init.sh`, which the new repo doesn't have
either way. The measured result is a repo that tracks `.env`. After the un-nest, confirm the
exemption worked: `git check-ignore -v .env` should exit 0.

**`.gitmodules` is not exempt, and a submodule inside the keep-set needs it.** That file lives at
the origin's root, so the forward delete takes it while the keep-set's gitlink survives: the file
list above shows the submodule path looking exactly right, and it is `git status` at the verify
step that reports it as deleted, with nothing to say why. If any kept path contains a submodule,
re-create the entries that repo needs before you push it.

**If the kept directory has its own `.gitignore`, reconcile before the move.** Two files exist at
that moment: the origin's, which the exemption above left at the root, and the kept directory's,
still nested — and the move will stop on the collision. Read both, reconcile them into one file at
the repo root, `git rm` the nested one, and `git add` the reconciled one — nothing further down
stages that edit for you. *Default: the union of the two.* Re-anchor any rule written against the
old path (`/Code/<name>/dist/` becomes `/dist/`); it matches nothing after the move. In Case 2 this
fires for every code folder, and never for `prompts/` or the docs hub, which have no ignore file of
their own. In Case 1 it usually does not fire at all, because the extracted directory is a
subdirectory of a code repo — the dead path-anchored rules it would have caught are what step 7's
repointing grep is for instead.

**The two checks do different jobs, and both are needed.**

- **The guard, before the move**, catches a keep-set that matched nothing. If the path is
  mistyped — or just the wrong letter case, since macOS treats `code/` and `Code/` as the same
  folder and git's pathspecs do not — the forward delete removes *everything*, the move loop iterates
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
exemption and no un-nest — just a forward `git rm` of what left (Case 1 step 6). In Case 2 there
is no surviving origin; every unit gets the mechanic above.

## Case 1 — Splitting a code repo in two

The **origin repo** survives and keeps its identity, its remote and its history. The **extracted
repo** is new. The docs hub and `prompts/` do not move.

*Tracking this as a STEP?* Reserve the number, branch, and archive the PLAN exactly as
`prompts/README.md` says — `prompts/` is untouched by this split, so none of that timing is
special here, which is why it gets no steps of its own below.

> **Where abort gets expensive.** Up to step 6, abort is cheap: delete the new directory, and
> delete the extracted repo's remote if you already created it. Nothing else has been touched, and
> neither the origin nor the hub has been pushed. From step 6 on the origin has been pruned.
> **Save anything untracked or ignored first** — `.env`, `.secrets/`, in-flight work. Nothing
> carries it. What step 6 moved across into the extracted repo needs saving most: that repo holds
> the only copy of it, and deleting it below destroys it. Then abort is
> `git reset --hard <the tip you wrote down at step 1>` in the origin — force-pushed if
> step 9 has already pushed it — plus deleting the extracted repo and its remote, and reverting
> the hub's step-7 and step-8 commits, pushed if step 9 pushed them: left standing, that registry
> row sends everyone else's `setup-workspace.sh` at a remote you just deleted. Do not reach for a
> re-clone: step 9 makes you push the prune, so re-cloning hands the split state back, and on a
> project with no remotes there is nothing to re-clone from. **Then put what you saved back**,
> where it sat before step 6 moved it — the reset brings the origin's tracked files back from
> git; these come back only from you.

1. **Confirm the mapping and the boundary** (questions 1 and 2). Write down the origin repo, the
   path being extracted, the new repo's name, and the origin's tip (`git rev-parse --short HEAD`,
   run in the origin): that is the last commit the two repos will share. **Re-read it once step 2
   has committed your working tree** — that commit moves the tip, and step 3 clones what step 2
   leaves. Record it here rather than at step 8, by which time the prune and the repoint have
   moved the origin past it. **Stop here, before step 3 builds anything** —
   show that written-out mapping and your answer to question 2. Deciding not to split is one of
   the answers, and this is the step where it gets made.
2. **Pre-flight: the branches that won't survive.** Run `git branch -a`. A clone carries every
   commit and every tag, but only the default branch arrives as a real branch — the rest exist
   only as remote-tracking refs and die with `git remote remove origin`, silently. The origin repo
   survives, so nothing is lost there; the risk is in-flight work on the *extracted* files, which
   lands in a repo where those files no longer exist. Merge or close everything but trunk before
   starting, or accept the loss knowingly. **Commit or stash your working tree too** — the clone
   takes committed state, so an uncommitted edit never reaches the new repo. Edits to tracked files,
   that is: anything untracked under the extracted path is what step 6 moves across by hand.
3. **Extract.** Run the mechanic above with `<keep>` set to the path being extracted. The new repo
   belongs at `Code/<new-name>/`, a sibling of the origin — but **substitute `<new-repo>` as an
   absolute path**, `<workspace-root>/Code/<new-name>/`, for the reason the mechanic gives: blocks
   2 and 3 re-enter the repo on their own first line. Step 8 records that same place in the
   registry row's `location:`, in the **workspace-relative** spelling `Code/<new-name>/` and never
   the absolute one you typed here, which `scripts/setup-workspace.sh` reports and skips rather
   than cloning into. The row is what puts the repo at that path on everyone else's machine.
   When it prints `git ls-files`, read it: it should look like the repo you asked for, at the
   root, with nothing left nested.
4. **Make it a repo, not a folder.**
   - **Its licence is the origin's, not the project's.** Carving a folder out of a repo does not
     relicense the code in it, and the origin may be one this project **adopted**, where the
     default command would state our posture over somebody else's code. The forward delete took
     the origin's root licence files along with everything else outside the keep-set, and the
     clone still holds them. List the origin's root, from the tip you wrote down at step 1:

     ```bash
     cd <new-repo>
     git ls-tree --name-only <tip>
     ```

     **Stop, show that list, and say which of those names are licensing.** No pattern picks them
     out reliably — `LICENSING.md`, `COPYING`, `COPYRIGHT`, `NOTICE`, `PATENTS` and a bare
     `UNLICENSE` all count — and nothing below re-derives the answer. An origin that carried none
     is a real answer.
     **Before restoring anything, look at this repo's own root**: if the extracted directory
     carried a licence, the un-nest already moved it up, and that one is the extracted code's own.
     Leave it, skip the restore for that name, and raise it in the chat — the command below
     overwrites without a word. Then restore the rest, a line per name, **except
     `LICENSE-THROUGHSTONE`**, which is our notice on our own material and comes fresh below:

     ```bash
     cd <new-repo>
     git checkout <tip> -- LICENSE        # one line per name; substitute them, don't loop
     ```

     Then the notice, **from the workspace root** — `cd` back first, the script resolves its
     target against where you are standing:
     `Code/<project>-docs/scripts/apply-project-license.sh --notice-only Code/<new-name>/`. It
     refuses nothing over a licence already in the repo, so nothing about this repo's licensing
     can stop the split. **Where the origin is a repo the method created this changes nothing** —
     its licence files are the project's own. Where it carried no licence at all, nothing is
     restored and this repo carries our notice alone.
   - Its README, per `runbooks/register-repo.md` step 2 — **the extracted folder's own README came
     up in the un-nest** (step 2 says which file counts: a regular root file whose name starts
     with `readme`, in any capitalisation, and ask if there is more than one), so if there is one,
     leave it and add a `## Role in <project>` section. Only a repo with no README gets
     `templates/repo-readme-template.md` stamped, with its role one-liner and Overview actually
     filled in. **If no `LICENSING.md` came across above, cut its `## Licensing` section back to
     the `LICENSE-THROUGHSTONE` sentence** — the link would dangle, and a root `LICENSE` here is
     the origin's rather than the project's, which is the opposite of what that section says.
   - `templates/env-example.txt` copied in as `.env.example` if it needs one.
   - **Its build and test entry point, and its CI gate.** The forward delete removed the origin's
     `Makefile`, CI config and test harness, so right now this repo has no way to build itself.
     Decide what it runs, then stamp the gate the same way a repo the method creates gets one:
     `templates/ci/code-repo-ci.yml` into this repo's `.github/workflows/ci.yml`, with its test
     command filled in — `templates/ci/README.md` says how, and `templates/repo-readme-template.md`
     asks for it on every created repo. If the extracted code also calls into code that stayed
     behind, decide that here too —
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
6. **Prune the origin.** `git rm -r -q -- <extracted-path>` and commit — naming *every* path in the
   keep-set, not just the first, and `git ls-files -- <extracted-path>` has to come back empty
   afterwards. That is the origin's only post-condition, and it is what a scattered keep-set needs:
   pruning one of two paths leaves the other tracked and live in both repos, and every check below
   still passes. Then **`ls -a <extracted-path>`** — do not look for dirtiness. `git rm` removes
   only tracked files. What stays behind is everything the repo never tracked: what it was told to
   *ignore* — build output, vendored files, snapshots, `.env` — which `git status` does not print
   at all, plus any untracked work you had in flight. Clear what is left by hand — but first move
   anything that belongs to the **extracted** repo over to it: `.env` and `.secrets/` are the usual
   ones, in-flight work is the one people lose, and the clone took committed state, so what is
   sitting here is the only copy. It goes where the un-nest would have put it —
   `<extracted-path>/.env` becomes `.env` at the new repo's root, or stays under
   `<extracted-path>/` when the keep-set was scattered and nothing was un-nested. Two reasons
   clearing the rest is not just tidiness: stale build output where the source used to be can keep
   the origin's tests passing against code the repo no longer contains, and step 7's `git grep`
   searches tracked files only, so it will not see it either. **Stop on the `ls -a` output, before
   deleting any of it** — the `git rm` above is recoverable from history and this is not: no
   remote, no mirror and no clone holds these files.
7. **Repoint everything that knew the old path.** `git grep -n -F "<old path>"` in the origin, in
   the extracted repo, **and in the docs hub** — including each `.gitignore`, where a rule anchored
   at the old path is now dead. Every hit is a repoint, a mention of history you keep on purpose,
   or a line of the method's own text that happens to use your path as an example — the hub carries
   the whole scaffold, and a hit under `runbooks/` or `templates/` is usually that third kind.
   Leave the method's own text; anything your project wrote is a repoint wherever it sits.
   Stage the files you repointed, not `git add -A` — this commit goes to a shared remote,
   and the origin's working tree still holds whatever was untracked there before you started. Note
   what the grep does not find: an `import` or package reference to what left carries
   no path, so it never appears. Whether the two sides still call into each other is step 4's
   boundary decision, and step 9's build-and-test is what fails if it was not made.
   **This step is not optional and is the easiest one to skip:** the hub's link checker resolves
   link targets into the code repos, so a *correct* split makes hub links dangle —
   `Code/<project>-docs/scripts/links.sh` passes right up to step 6 and fails from there until
   this step repoints them. It does not check the hub's `inputs/`, whose imported documents are
   kept as they arrived: a hit in one of them is history you keep, not a repoint. Step 7 is what
   makes step 9 satisfiable.
8. **Register it** — run the register action (`runbooks/register-repo.md`), which writes the row
   and the Architecture Overview entry. **Read that row's `location:` against where the repo
   actually is, before the action commits** — the absolute `<new-repo>` you typed at step 3 and
   the row have to name the same directory, the first spelled from `/` and the second
   workspace-relative (`Code/<new-name>/`). This is the one moment both are in front of you — the
   absolute path lives only in the command you typed — and check 10 of `check.sh --check-in` reads
   the rows and never the paths, so a row pointing where the repo is not passes the check-in and
   fails on everyone else's `setup-workspace.sh`.
   **Add a `provenance:` block to that row before the action reaches its step 3**, which reads it;
   putting it in alongside step 1's row also keeps the registration to one commit. It names the
   repo this one came from, today's date, and the last commit the two repos share — the tip you
   wrote down at step 1, which resolves in both. Nothing else writes that block. Your-row-only, per `collaboration.md` §5.
   The action re-does step 4's licence and README on its way through and finds them already
   done — it reports those `✓`, and the repo commit `n/a` if step 4 left nothing new to commit.
   That is the expected result here, not a sign you missed something. **The licence step is the
   one to watch**: the row reads `added_as: created`, so the action reaches for the project
   posture and meets the licence step 4 left. Where the two match it reports them already current;
   where they differ the script stops, which is `register-repo.md` step 3's own case — run its
   `--notice-only` command instead and say in the chat which licence this repo carries. **Where
   step 4 restored nothing**, there is nothing to meet and nothing stops it: that is the same
   step's empty-root case, so ask before the posture is stamped.
9. **Verify.** **Push the origin, the extracted repo and the hub first** — step 5's push came
   before the prune, the repoint and the registration, and nothing since has sent anything.
   - Both repos **build and test**.
   - `git status` shows nothing new in either repo — in the origin, only what was already
     untracked before you started; in the extracted repo, only what step 6 moved across — and each
     local trunk matches its remote: that is the check that what you can see is what everyone else
     receives.
   - The step-7 grep now returns only what you decided to leave: the historical mentions, and
     the method's own text in the hub.
   - `git log --follow` and `git blame` resolve across the un-nest in the extracted repo, and the
     pre-split commit exists in both.
   - The extracted repo's root holds the licences step 4 settled on — the ones you restored, any
     the un-nest brought up, and our notice — and nothing else. Nothing further checks:
     `check.sh` has no licensing check and `links.sh` skips app repos, so a restore that was
     skipped shows up here or nowhere.
   - `Code/<project>-docs/scripts/links.sh` is clean.

## Case 2 — Converting mono-repo-for-now to multi-repo

The workspace root stops being a repository. `prompts/`, the docs hub and each code folder become
repos of their own. This happens at most once per project.

**Every unit is a whole folder, and no unit sits inside another.** Naming `Code/shop/billing` as a
unit alongside `Code/shop` is what you reach for when you want the split itself to do the dividing,
and it is the one shape this case cannot survive: `billing/` comes out at the root of its own repo
*and* stays tracked and live inside the storefront's. Case 1 pairs every extraction with a prune of
the origin and says why (its step 6); here there is no surviving origin, so nothing subtracts the
nested unit from the repo that also carries it. **No check in this case catches it** — `git status`
is clean in every repo, step 10's *"nothing left under the path it was moved out of"* is true in
every repo, and `check.sh --check-in` reads rows, not contents. It surfaces after the swap, with
the old remote already read-only. A scattered keep-set naming the storefront's other folders is not
the way out either: two or more keep paths buy no un-nest and no post-condition (see the mechanic),
so that repo's files stay at `Code/shop/web/…` instead of at its root. **If `billing` should be its
own repo, move it out from under `Code/shop` first** — a plain `git mv` in the mono repo, committed
before step 5 clones anything — and split two folders that sit beside each other.

> **You build the new workspace beside the old one and swap at the end.** Everything up to step 11
> happens in `../<project>-split/`, and until step 4 the live workspace is untouched, so abort is
> deleting that directory. Do not start by deleting or rewriting anything you have. From step 4 on,
> two things live outside the build directory and abort has to undo them by hand: the STEP
> reservation committed and pushed on the live trunk, which becomes a row to mark **Abandoned**,
> and the remotes step 7 creates and pushes, which have to be deleted. Left standing, a teammate
> cloning the hub from them gets a complete, green workspace for a split nobody did.

1. **Confirm the mapping** (question 1), and decide **where each root file goes**. Derive the list;
   don't work from memory:

   ```bash
   git ls-files -- . ':!Code/' ':!prompts/'    # everything tracked that no keep-set claims
   ```

   Ten entries on a stock mono root, or nine on a proprietary one, which has no `LICENSE` — but
   read the list the command printed rather than the count: it moves whenever the generator does.
   *Default disposition:* the licence files are stamped into each new repo by
   `scripts/apply-project-license.sh` (step 6); `CLAUDE.md`, `AGENTS.md` and
   `doctor.sh` change kind at this split — they stop being committed files and become per-machine
   pointers regenerated by `scripts/setup-workspace.sh` (step 8); `init.sh` has done its job
   and is dropped; and the root `.github/workflows/`, which `init.sh` placed for a mono project, is
   dropped too — the docs hub carries its own copy, which becomes that repo's own CI when the hub
   becomes a repo here. **Do not carry it to the new workspace root:** that root stops being a
   repository, nothing would run it there, and `scripts/check.sh` check 7 warns on a root entry it
   does not expect, which step 10 reads as a failure. The last two need no decision of their own:
   the root `.gitignore` is the one path the mechanic exempts from every forward delete, so each
   new repo starts from a copy and reconciles it at step 5, and `Upcoming Prompts/.gitkeep` crosses
   with its folder at step 9. Anything your project added to the root is yours to place.
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
     state, so an uncommitted edit reaches no new repo and nothing flags it. That means edits to
     tracked files; the untracked ones are already on the list above and cross by hand at step 9,
     so there is nothing to sweep in here. Stashing is not an alternative either: a stash lives in
     the repo you are about to replace, so pop it and commit before step 5.
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
   # <build-dir> is the ABSOLUTE path of ../<project>-split/, where the new workspace is assembled.
   # A relative <new-repo> breaks blocks 2 and 3, which cd back in on their own first line.
   git clone --no-local . <build-dir>/prompts        # <keep> = prompts
   git clone --no-local . <build-dir>/Code/<name>    # <keep> = Code/<name>
   ```

   Reconcile the ignore file, un-nest, and read the file list each time. The reconcile fires for
   every code folder: the file the clone left at the root is the *workspace* root's, which carries
   none of that code repo's build ignores, and the folder's own is still nested.
6. **Stamp each new repo, and commit it.** Run
   `Code/<project>-docs/scripts/apply-project-license.sh <repo-path>/` once per repo **from the
   build directory's root** — that root is the new workspace root, so every path is written
   relative to it exactly as the registry writes it. **A repo whose registry row reads
   `added_as: adopted` takes `--notice-only`**, exactly as `runbooks/register-repo.md` step 3 says,
   and **no row's `added_as:` changes here** — it is written once, and the rule that a split-out
   repo is `created` is about the row Case 1 writes for a repo it carves out, not about a folder
   that already had one. This split makes that folder a repository, but it does not make its code
   ours to license, and the default command would state our posture over their code: a project
   `LICENSE` and a `LICENSING.md` where that folder carries no licence of its own, and — where it
   carries one — a refusal that stops the split in the middle of this step.
   For a repo we did create, if the script stops because a licence is already there, run
   `--notice-only` for it so the notice still lands and raise the licence with the person running
   the split — again step 3's rule, and it holds here. Then **commit the result in that repo**. The
   script writes new, untracked files, step 7 pushes, and nothing else in this procedure commits
   them — skip this and a repo reaches its host with none of the licensing artifacts its posture
   requires, while your own copy on disk shows them.

   **The test gate a code folder already carries starts running at step 7.** A code repo is
   stamped with `templates/ci/code-repo-ci.yml` when it is scaffolded, and in a mono project that
   workflow has never run once — GitHub reads workflows only at a repository root
   (`templates/ci/README.md` §2). The un-nest at step 5 carries `.github/` up with everything
   else, so from step 7's push it sits at a repository root with a remote behind it and gates
   every push and pull request. **If its `Configure me` step was never replaced it `exit 1`s, and
   the repo's first push is red** — the gate doing exactly what it was stamped to do, on a repo
   you created a moment ago. Open each code repo's `.github/workflows/ci.yml` before you push and
   fill in its toolchain and test command — **and commit that edit with the rest of this step**,
   since `ci.yml` is a tracked file the clone brought across and step 7 pushes only what is
   committed — or go in knowing the gate stays red until somebody does. A folder that was never
   stamped has nothing to go live, and this case does not stamp one: each repo brings across the
   gate it already had. Step 1's CI decision is a different one — the root workflows the new
   workspace root must not carry — and step 10's *builds and tests* is your machine rather than
   the gate.
7. **Remotes.** Create each **private** — every one of them now carries the whole mono repo's
   history, and widening any of them is a separate decision to make deliberately later, not a
   side effect of the split. Push trunk, then record each repo in `registries/repos.yml`.
   **If that file carries a row for the workspace root** — `location: "."` — **delete it first.**
   The root stops being a repository at this step, so the row describes nothing afterwards; what
   replaces it is the folder rows already in the file, which become real repos here. A registry
   written before the root row existed has none, in which case there is nothing to delete and
   nothing else about this step changes.
   **Run the register action** (`runbooks/register-repo.md`) **once per code repo, from the build
   directory's root** — that is the workspace root it means here; run it from the live one and the
   row and the entry land in the hub step 11 renames aside. It records that repo's `remote:` and
   writes its Architecture Overview entry alongside the row. This step is what makes that possible:
   until now those rows pointed at folders inside one repository, and from here they are
   repositories of their own. **The docs hub and `prompts/` are the exception** — the action runs
   once per *code* repo, and `init.sh` wrote those two rows already, so write their `remote:` fields
   by hand.
   The action also writes that repo's README — a `## Role in <project>` section, or a refresh of
   one it stamped, whichever `register-repo.md` step 2 decides — and commits it
   **in that repo** (`register-repo.md` step 5), so **push each code repo again once the action has
   run** — that commit lands after the push above and nothing else sends it, and left behind it
   fails step 10's local-trunk-matches-remote check.
   Every **remaining** row is now a split-out repo, so each also gets a `provenance:` block, which
   the action does not write. **Add it to the row while you are there** — for a code repo that
   means before the action's commit, so its registration stays one commit. It names the mono repo,
   today's date, the last commit they all share (the mono tip the clones were taken from at step 5;
   that workspace is on disk until step 11, so read it there), and the `origin` URL you wrote down
   at step 2 as `archive_remote:`. **That commit has to exist on the archive too** — if the mono
   trunk you cloned at step 5 was ahead of its remote, push it there before you record these,
   because step 12 makes that host read-only. **Delete the mono-repo-for-now note** — the paragraph
   opening `Mono-repo-for-now:` — which stops being true the moment this step runs.
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
   Every unit keeps its workspace-relative path across the split, so this is a plain copy from the
   old workspace into the build directory: `Code/<name>/.env` is `Code/<name>/.env` on both sides.
   The re-anchoring step 10 asks for is a different thing — it is how the same file reads from
   *inside* the new repo, where that path is just `.env`.
10. **Verify the build directory before you swap.**
    - Each new repo: `git status` showing nothing but that repo's entries from step 2's
      `git ls-files --others --exclude-standard` list, re-anchored to its new root; local trunk
      matching its remote; `git check-ignore -v .env` exiting 0; and nothing left under the path
      it was moved out of. Anything from step 2's *ignored* list showing up as untracked — a
      `node_modules/`, a `dist/` — means that repo's ignore file did not survive step 5's
      reconcile.
    - Each code repo **builds and tests**.
    - `Code/<project>-docs/scripts/check.sh --check-in` at **0 fail(s), 0 warning(s)** — warnings
      do not fail the run, so "green" is not the criterion. **Run it with that flag:** the
      repo-registry check is the only check in `check.sh` that reads what step 7 just wrote, and
      it runs only under `--check-in`. Without the flag, a registry whose rows lost a `location:`
      still reports `RESULT: OK`.
    - `Code/<project>-docs/scripts/links.sh` clean.
    - A **real teammate clone**: a fresh empty directory, clone the docs hub into
      `Code/<project>-docs/` inside it, run `Code/<project>-docs/scripts/setup-workspace.sh` from
      that new workspace root, and confirm every registered repo actually arrives.
    - The pre-split commit resolves in every new repo.
11. **Swap.** **Stop before the rename** — show which directory becomes which. Then **rename** the
    old workspace aside — do not delete it — and move the build directory into its place. Abort is
    still deleting the build directory, plus the step-4 and step-7 cleanup above. Delete the old
    workspace only after you have worked in the new one for a while: it is the only copy of
    anything step 2's lists missed, and no mirror holds untracked or ignored files.
12. **Retire the old remote**, per step 2's decision. *Default:* delete its contents in one tip
    commit, leaving a `README.md` that says the history is still there and how to reach it, then set
    the host's permissions to read-only. **Never delete refs**, and author that commit on a fresh
    clone of the host, not in your live workspace. Do this **after the swap is verified, never
    before** — a complete pushed copy stays on the host through the whole destructive window. That README needs
    one sentence for anyone else holding a clone: *start a fresh empty folder, clone the docs hub
    into `Code/<project>-docs/` inside it, and from that folder run
    `Code/<project>-docs/scripts/setup-workspace.sh` — do not reuse your old project folder.*
    Re-onboarding in place leaves the new repos nested inside the retired one, and every check
    passes. **Stop before you push that commit** — show the README and the tree it leaves behind.
13. **Write the STEP's PLAN** and archive it into the new `prompts/` repo — at `<phase>/step-NNNN/`
    and `STEP-index.md` from that repo's root, since the un-nest at step 5 moved `prompts/`'s
    contents up to it. Then mark the STEP done. Written now rather than at step 4, it never has to
    pass through a forward delete. *Skip this if you skipped step 4.*

## Appendix — purging history first

You are here because a credential or a large binary is in the history and you do not want it copied
into a second repo. This is the **purge** procedure, not an escape hatch from the default: it
rewrites history, so it happens *before* either case, on a mirror, once.

**Rotate the credential first.** A rewrite does not reach the clones your teammates already have,
or the copies on the host until it garbage-collects, or anything a CI log captured. Rotation is the
control; the rewrite is cleanup.

**Reconnaissance, before you rewrite anything.**

```bash
git clone --mirror --no-local <origin> ../purge-work.git   # work on a copy, never your only one
git -C ../purge-work.git filter-repo --analyze             # path + rename reports (needs the tool below)
git -C ../purge-work.git for-each-ref --format='%(objectname) %(refname)' > ../refs-before.txt
```

The `--analyze` reports are how you build the path list. **Neither tool follows renames.** If the
file ever moved, every one of its old paths has to be on the list, and a path you miss fails
silently in whichever direction you are filtering. Keeping a set of paths truncates history at the
ones you did not name — one reported case lost 119 of 144 commits of `--follow` history on a plain
directory filter. Removing a set leaves the blob in history under the old name, and the tool
reports success: on a purge, that is the credential you came here to delete.

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

Every SHA changes, so every line of that diff differs — read it for refs that *disappeared*, not
for refs that moved. The collapse above needs a per-branch check instead: `git rev-list --count
<trunk>..<branch>`, before and after. A branch that had commits of its own and now returns zero has
been folded into another line of history, under a SHA that is not any other ref's tip, so the diff
will not show it. Decide what each one should be before you push anything.

**And confirm the purge itself.** Neither of those checks looks at the blob, and the failure this
section opens with — a path you did not name, the tool reporting success — is invisible to both:
`git -C ../purge-work.git log --oneline --branches -- <path>` has to print nothing for every path
on your list, and the blob must no longer resolve.

**What a purge costs you**, so nobody is surprised: every SHA changes, so every commit reference
recorded anywhere — `reviewed_commit:` in `registries/security-reviews.yml`, SHAs in reports and
ADRs, links in issues — stops resolving, and everyone re-clones. That is the trade for not carrying
the blob.

**Then hand back.** The purged mirror is what the split reads, not a side artifact: Case 1 clones
the origin you are standing in and Case 2 step 5 clones `.`, so a split run beside a purge copies
the blob into every new repo instead. Copy your untracked and ignored files aside first — a fresh
clone has none, and Case 2 step 2's two lists come back empty once you re-clone. Then force-push
the mirror over the origin host, re-clone your workspace from it, and start the split there.

**If the motive is purely size**, there is a cheaper answer that rewrites nothing: let one new repo
inherit the origin's identity outright rather than cloning it. Move the `.git` directory into the
folder that is becoming a repo, then inside it `git rm -r --cached .`, `git add -A`, and commit. It
comes out with the complete un-rewritten history and `--follow` and `blame` resolving through the
path change — but only one repo can inherit it, and the workspace root stops being a repo the
moment you move `.git`, so this only makes sense as part of Case 2. **Do it last**, after every
other unit has been cloned at step 5, not here before Case 2 starts: the move drops those units
from HEAD, so their forward delete keeps nothing and the guard fires on a path you typed
correctly. **Push the mono trunk to its remote before you move `.git`** — step 7 records a commit
that has to exist on the archive, and after the move nothing on disk can put it there: the
workspace root is no longer a repo, and the inheriting repo's `origin` gets repointed below. Then
**move the inheriting folder into the build directory** with the rest — step 11 moves that
directory into place and would otherwise strand this repo in the workspace you renamed aside. Its
ignored files travel with it untouched, so step 9 has nothing to carry for it. And be clear what
it buys — one copy of the object graph, not the blob. Every other unit is still a clone and still
carries it.

**This replaces the clone and the forward delete, not the rest of the mechanic.** `origin` still
points at the mono repo, so `git remote set-url` it to this repo's own remote before step 7 —
otherwise "push trunk" pushes this tree over the mono repo's, and nothing errors. The root
`.gitignore` is not here to be exempted: copy it in and reconcile it with the folder's own, as
step 5 does — before the `git add -A` above, or that commit takes in everything those rules would
have kept out. And `git add -A` commits every untracked file in the folder, where a clone would
have left them untracked — so end with `git ls-files` and stop on it, like every other repo.
