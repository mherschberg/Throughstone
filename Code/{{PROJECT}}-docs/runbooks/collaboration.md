# Runbook — Working Together (multiple developers & agents)

The method (`METHOD.md`) describes the structure; this runbook covers how more than one
person — or more than one AI agent — works in it without stepping on each other. Read it
when a second contributor (human or agent) joins; solo, almost everything here is a no-op.

## What this runbook owns — and what it leaves alone
This method is opinionated only about **its own artifacts**. Everything a normal team
already has tooling for, it leaves to that tooling.

- **The method defines:** how a global **STEP number** is reserved without collisions, how
  STEPs are isolated on branches, how the shared **`prompts/STEP-index.md`** is edited without merge
  pain, how decisions are socialized through **ADRs** (and their numbers reserved like STEP
  numbers), and how **`prompts/`** (shared history) is appended by many hands.
- **Standard practice, not the method's job:** your branching model beyond the one naming
  rule below, PR mechanics and review gates, code-review tooling, issue/bug tracking, CI/CD,
  and release versioning. Use whatever your team already uses.

## The model in one breath
**Every STEP lives on its own branch, so concurrent STEPs are the normal case — git keeps
them isolated.** There is no repo lock and no "one STEP at a time" rule. What must be
coordinated up front are the sequential shared numbers — the **global STEP number** above all
(it gates starting work), and **ADR numbers**, reserved the same way (§6); two contributors
must never reserve the same one. Beyond that, the method *warns* when two in-flight STEPs look likely
to touch the same code, but it never blocks them — branches make overlap safe, just not
free.

## 1. Branch per STEP — even solo
Every STEP is worked on a branch named for it:

```
step-NNNN-short-name        e.g. step-0042-payment-webhooks
```

- Use the **same branch name in every repo the STEP touches.** A STEP that spans
  `acme-api` and `acme-web` has a `step-0042-payment-webhooks` branch in *each* — that's how
  one logical STEP stays recognizable across repos.
- This holds **even when you're solo.** It costs nothing alone and means the workflow is
  identical the day a second contributor arrives — no mode switch.
- Branch lifetime, PR gates, and how the branch merges are **standard practice** — the method
  only fixes the name and the cross-repo consistency.

## 2. Reserving a STEP number (the one hard rule)
STEP numbers are **global and never reset** (`METHOD.md` §1, §8). `prompts/` is the one repo
every contributor shares, so the index in it is the registry of record. Reserving a number
and proposing the STEP are the **same atomic act**, and it happens **before** you branch or
write anything.

**Protocol — identical for humans and agents:**

1. **Pull `prompts/`.** Get the current `prompts/STEP-index.md`.
2. **Allocate** the next number: `max(existing STEP numbers) + 1`.
3. **Add the row** to `prompts/STEP-index.md` (number, title, owner = you, status, one-line scope,
   and the repos you expect to touch).
4. **Commit small and push immediately** — a dedicated `reserve STEP-N` commit on `prompts/`'s
   **shared trunk** (`{{TRUNK_BRANCH}}`), separate from any other change. `prompts/STEP-index.md` is a shared
   registry: the reserve commit *and every later edit to it* (status flips, archival rows) land
   on the trunk, **never on a `step-NNNN` branch** — the push-reject that referees the race only
   fires when everyone pushes to the same branch, and the duplicate scan (step 6) only works if
   there's one index to scan. The push is what makes the number real and visible to everyone.
5. **If the push is rejected** (someone reserved concurrently), `pull`, then **re-read the
   table, recompute `max + 1`, and move your row to that number**, and push again — **repeat
   until the push is accepted.** Under heavy contention you may renumber more than once.
   Nothing references the number yet, so renumbering is free.
   - **Reserving a batch renumbers as a block.** When the planning session
     (`templates/planning-session.md`) lays down many STEPs in one commit and loses a push
     race, move the **whole batch** above the new `max` — not just one row — then push again.
6. **Scan for a duplicate before every push — even on a clean merge.** A rejected push is *not*
   the only way a duplicate appears: two contributors who each *append* a row merge with **no
   conflict** (see the note below), so git won't flag it. After any pull/merge and before you
   push, scan the index for a repeated number:
   ```
   grep -oE '^\|[[:space:]]*STEP-[0-9]+' prompts/STEP-index.md | grep -oE 'STEP-[0-9]+' | sort | uniq -d   # prints nothing when clean
   ```
   If it prints anything, recompute `max + 1`, renumber your row, and re-scan until it's empty.

> **Renumber even when the pull merges cleanly.** Two contributors each *append* a new row,
> so the edits land on different lines and git merges them **without a conflict** — leaving
> two `STEP-6` rows that no merge flags. A clean pull is *not* proof you're safe: the duplicate
> scan (step 6) is what catches it, so run it after any pull/merge, recompute `max + 1`, and
> renumber your row; never just re-push the merge commit. (This is also why reserving happens
> *before* you branch — once a `step-NNNN` branch exists in several repos, the duplicate is no
> longer free to fix.)

Do not create the `step-NNNN` branches or start work until the reserving push succeeds.
After that the number is yours; everyone who pulls sees it.

> If your remote supports **file locking** (GitHub / Bitbucket / GitLab), you can lock
> `prompts/STEP-index.md` for the reserve edit and skip the push-race entirely — see §5. The protocol
> above still stands as the baseline (and the duplicate scan is still worth running).

**Flip the row to `In progress` when you start — and push the flip.** Reservation leaves the
row `Planned`; the overlap warning (§4) reads in-flight STEPs *from the shared index*, so the
moment you cut the `step-NNNN` branch and begin work, set the row's **Status** to `In progress`
in a small commit pushed to `prompts/`'s trunk (the same your-row-only edit as reserve, §5).
The later `Done` / `Abandoned` transitions are pushed the same way. A STEP being worked must
never be left at `Planned` on the shared branch — or have its flip sitting unpushed locally —
or it's invisible to everyone else's overlap check.

> Most numbers are never allocated this way under contention: the **planning session**
> (`templates/planning-session.md`) lays down all of a phase's STEP numbers in one batch
> after STEP-1. The reserve-then-push dance only matters for **ad-hoc STEPs** added later
> (bugs, inserted work) — which is exactly when two people might grab a number at once.

## 3. The shared coordination surface is the index row
While a STEP is in flight its PLAN and substep prompts live in `Upcoming Prompts/`, which is
**per-machine scratch — not a repo, not shared** (`METHOD.md` §5). So a teammate **cannot see
your in-flight PLAN** — they see only your **row in `prompts/STEP-index.md`**. Everything others need
to coordinate must therefore be *in that row*:

- **Owner** — the single person who owns this STEP. **A STEP and all its substeps have one
  owner** — substeps aren't parcelled out to different people. If a body of work needs to
  split across people, split it into separate STEPs, each with its own number, branch, and
  owner; that keeps the unit of ownership the same as the unit of isolation (the branch). The
  owner is informational here (who to talk to), recorded in the STEP PLAN and surfaced in this
  row.
- **Status** — Planned · In progress · Done · **Deferred** · **Abandoned**. A STEP that is
  consciously not needed under the current project shape but may be revisited later is marked
  **Deferred** with a revisit trigger in the PLAN/risk register. A STEP that was reserved but
  won't be built is marked **Abandoned** — its row **stays** (never delete it) so its number is
  never reused (`METHOD.md` §8). `max + 1` always counts deferred and abandoned numbers; don't
  reissue them.
- **Repos (projection)** — the repos you *expect* to touch. This is a **projection, not a
  guarantee** — scope shifts as a STEP is worked, and that's fine. It exists to power the
  overlap warning below, not to reserve anything. The PLAN carries the same field
  (`templates/step-plan-template.md`), but **the index row is the authoritative copy for coordination** —
  it's what teammates read. **If a STEP grows to touch a repo not in its projection, update the
  row** (and keep the PLAN's copy in sync) — the projection only protects others if it's roughly
  current, and a stale one makes the overlap warning miss real collisions.

The full PLAN stays private in `Upcoming Prompts/` by default (the lean choice). A team that
wants in-flight PLANs visible can opt in: make `Upcoming Prompts/` a repo (`METHOD.md` §5
allows this), or commit the PLAN onto the STEP's `step-NNNN` branch in the docs hub (it still
archives to `prompts/` on completion, §7). Most teams don't need to.

## 4. Overlap warning — advisory, never a block
Branches make two STEPs touching the same code *safe* (they merge later) but not *free* (the
merge can hurt). So the method surfaces likely overlap and lets you decide:

- **The shared index row is the coordination surface** (§3) — it's the only thing others can
  see of your in-flight work, so it's the primary check. **When you start a STEP**, read the
  **in-flight** rows in `prompts/STEP-index.md` — `In progress`, plus any `Planned` row that already has
  a `step-*` branch — and compare their **Repos (projection)** against your STEP's scope. If
  they overlap, **say so** — then proceed. It's a heads-up, not a gate. (This is why the
  `In progress` flip must be *pushed*, §2: an unpushed status makes a worked STEP invisible here.)
- **Agents must do this check and warn the user** before starting work (see `AGENTS.md`).
- **Optional extra signal — only if your team pushes its `step-*` branches.** A *remote* scan
  (`git ls-remote --heads origin 'step-*'`, or `git fetch` then `git branch -r --list '*step-*'`)
  flags any repo carrying more than one live `step-*` branch, and catches a STEP whose row
  someone forgot to flip. But many contributors don't push a branch until PR time, so it sees
  nothing for purely-local work — treat it as a bonus, not the primary check, and never lean on
  a local `git branch --list` (it never sees a teammate's branch). Wire the remote scan into CI
  if you want it.

> **The warning is repo-granular — read it as a heads-up, not a verdict.** It fires whenever
> two STEPs name the same repo, even if they touch unrelated files (expect over-warning in a
> multi-repo project), and it is **meaningless in a mono-repo**, where every STEP touches the
> one repo so it would fire for every pair. In mono-repo mode, fall back to the PLAN's
> file/area notes or a one-line "I'm editing X" to teammates. If a repo is large, putting a
> subsystem or path hint next to it in the projection makes the signal sharper.

## 5. Editing shared files without merge pain
A few files are global and edited by everyone. They fall into two kinds:

**Table files** — `prompts/STEP-index.md`, `adr/README.md` (the registry), each phase `README.md`,
and `registries/repos.yml`. These conflict only when people reflow them:
- Edit **only your own row(s)**; never re-sort or reformat the whole table.
- Land index/registry edits in **small, dedicated commits** and push promptly.
- A conflict here is almost always two edits on **different rows** — keep both.

**Narrative files** — `architecture/NN-*.md`. Prose does **not** merge cleanly, and an
architecture-doc collision is the costliest merge there is, so these are serialized by *not
having two STEPs edit the same doc at once*. The overlap warning (§4) is the catch — and
although a docs-hub hit over-warns in general (§4 note), **for narrative files treat it as a
real prompt to serialize, not noise**: when two STEPs both touch the docs hub, confirm you're
not both editing the same doc before proceeding. A doc/subsystem hint in the **Repos
(projection)** sharpens it. For a small team, a one-line "I'm re-running session 1.5" is
enough. Re-running a session later (`METHOD.md` §4) is fine — just not concurrently with
someone else editing the same doc.

### If your remote enforces file locks, use them on these files
GitHub, Bitbucket, and GitLab all support **Git LFS file locks** (`git lfs lock <file>` /
`git lfs unlock <file>`). On a supported remote, locking a shared file turns the
edit-without-merge-pain problem into true mutual exclusion — like a table-level DB lock:
**lock → pull → edit your row (or the doc) → commit → push → unlock**, holding the lock *only*
for that brief edit. It's most valuable on the **narrative files**, where a concurrent merge is
the costliest case above — there the lock guards against a *prose merge*, not a number clash.
(Architecture-doc numbers need no reservation ceremony at all: the docs are separate files with
descriptive names — `06-security-model.md`, not just `06` — so a duplicate number shows up
visibly in `git status` rather than merging into a silent duplicate the way two index rows do,
and it's fixed by renaming one file. The reserve-and-scan protocol is only for the shared
*append-into-one-file* registries: STEP numbers and ADR numbers.) Mark the files lockable once,
in each repo's `.gitattributes`:

```
# prompts/.gitattributes
STEP-index.md      lockable
# Code/{{PROJECT}}-docs/.gitattributes
adr/README.md      lockable
architecture/*.md  lockable
```

The `lockable` attribute does **not** require storing the file in LFS — leave off the
`filter=lfs` part so these stay normal, diffable text files; you only want the lock, not blob
storage.

This is an **optimization, not a replacement.** Locking is a remote-host feature, so it can't
be the method's baseline (the method is tool-agnostic — solo, no remote, and other remotes have
no locks), and a lock can be force-broken (`git lfs unlock --force`) or left dangling by a
crashed client. So the universal protocol stays in force underneath it: in particular, **still
run the duplicate scan (§2) after you pull even while holding the lock** — it's cheap insurance.
And never hold a lock while you do other work, or you serialize everyone.

## 6. ADRs are how decisions are socialized
In a team, an architecture decision isn't yours alone — ADRs are the channel for proposing,
reviewing, and recording it. The ADR template already carries the needed states
(`Proposed | Accepted | Rejected | Superseded`).

- **Solo:** author straight to **Accepted** — you're the authority.
- **Team:** a significant decision lands as **Proposed**, gets reviewed (PR / discussion),
  then is flipped to **Accepted** by whoever the team has designated. Record *who accepts*
  in `adr/README.md` (a one-liner: consensus / tech lead / review board) so the authority
  rule is on disk, not folklore.
- **Re-running a session that changes a decision others depend on** goes through this flow —
  you're superseding an ADR, so write the new one as **Proposed**, review it, then **Accept**
  it and mark the old one `Superseded by ADR-XXXX`. Don't silently revise a shared decision;
  the superseding ADR in the registry is how dependents find out.
- **Reserve the ADR number like a STEP number.** ADR numbers are sequential and never reused,
  and the registry in `adr/README.md` is shared — so two authors each appending an `ADR-0005`
  row merge **cleanly** into a silent duplicate, exactly as two `STEP-6` rows do (§2). A clean
  pull is not proof you're safe. Use the same protocol, on the docs hub's shared trunk: pull,
  take `max + 1` over the registry, add your row and create the `ADR-NNNN-*.md` file, then
  **commit and push immediately** in a dedicated commit. Before every push, even on a clean
  merge, scan for a repeated number:
  ```
  grep -oE '^\|[[:space:]]*ADR-[0-9]+' adr/README.md | grep -oE 'ADR-[0-9]+' | sort | uniq -d   # prints nothing when clean
  ```
  **If it prints anything — or the push is rejected — recompute `max + 1`, renumber your ADR
  (file + row), and push again;** never re-push the merge as-is. Solo with no remote, this is
  just a local edit.
- **Also announce a new ADR out of band.** Reservation prevents a number collision; it doesn't
  tell anyone a *decision* was made. When an ADR is created or proposed, announce it however
  your team already communicates (email, Slack, the PR). Agents: prompt the user to do this
  rather than assuming it's been done.

## 7. `prompts/` is shared history, appended by everyone
`prompts/` spans all the code repos and is **never rewritten** (`METHOD.md` §5). Many
contributors append to it:
- On completion, each gathers their STEP's loose files from `Upcoming Prompts/` into a new
  `step-NNNN/` folder in the phase (`prompts/001-mvp/step-NNNN/`) and adds a row to that
  phase's `README.md`.
- Archived STEP folders are **write-once**, so they essentially never conflict. The only
  shared files touched on archival are the phase `README.md` and `prompts/STEP-index.md` — handle
  both with the your-row-only rule (§5).

## 8. A STEP that spans repos
A STEP is a **project-wide** unit, recorded once in `prompts/` regardless of how many code
repos it touches — that single record is what keeps the history coherent across repos.
- Its **PLAN lists the repos it touches and the order they merge in** (cross-repo
  sequencing). Reference commits / PRs / tags where ordering matters.
- It uses the **same `step-NNNN` branch name in each repo** (§1).
- If it creates a new repo, add it to `registries/repos.yml` (your-row-only, §5).

## 9. Going from solo to team
The *structural* habits above you already practice solo — branch-per-STEP (§1) and allocating
the STEP number in the index (§2, a plain local edit with no remote). What **switches on** when
the second contributor arrives is the *coordination*: the push/renumber race (§2), the overlap
warning (§4), the shared-file your-row-only discipline (§5), and the `Proposed → Accepted` ADR
flow (§6). The transition is mostly mechanical (and assumes the **multi-repo** layout — if
you're still mono-repo-for-now per `METHOD.md` §7, split first: a team needs shared remotes
for the reservation push-race to work, and the overlap warning (§4) is meaningless in a single
repo):

1. **Stand up the shared remotes — and push your existing history to them first.** A solo
   dev has been committing locally with no remote, so the order matters: (a) create the remote
   for `prompts/`, the docs hub, and each code repo, then **`git push` your existing history
   to each** — otherwise newcomers clone empty repos and the STEP-number registry of record is
   gone; (b) add the `remote:` fields in `registries/repos.yml`; (c) have each new contributor
   run `scripts/setup-workspace.sh` to clone them. Number reservation (§2) relies on this
   shared `prompts/` remote.
2. **Record the ADR authority rule** in `adr/README.md` (§6) — decide once who can Accept a
   decision.
3. **Point everyone here.** New contributors read this runbook (and `AGENTS.md`) before their
   first STEP.

That's the whole transition: shared remotes, a written authority rule, and the branch-per-STEP
+ reserve-the-number habits you were already practicing solo.

## Multiple AI agents
Agents follow the **same rules as people** — the protocols above are written to be executed by
either, because all the coordinating state lives on disk (`AGENTS.md`, `METHOD.md`, the index,
the ADRs), not in any one tool's memory or conversation. In particular an agent must:
- **Reserve the number before working** (§2): pull, allocate, push, and renumber-and-retry
  until the push is accepted — recomputing `max + 1` even when the pull merged cleanly.
- **Read the index first and warn on overlap** (§4) before starting a STEP.
- **Edit only its own rows** in shared table files (§5).
- Use its own `step-NNNN` branch (§1), so parallel agents — including ones in separate git
  worktrees — never collide in the working tree.

> **Worktrees isolate code, not the number reservation.** The reservation race (§2) is
> refereed by `git push` being rejected, which only happens between **independent clones
> sharing a remote**. Git worktrees share one clone (one `.git`, one set of refs) and can't
> both check out `prompts/`'s shared branch (where the reserve commit lands) at once, so
> there's no push/reject between them. Worktree
> agents get working-tree isolation for *code*, but to reserve a STEP number an agent should
> work from its **own clone of `prompts/`** with the shared remote.

A fresh agent picks up wherever the files are; no shared conversation is needed.
